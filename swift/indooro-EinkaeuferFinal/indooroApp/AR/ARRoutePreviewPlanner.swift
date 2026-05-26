import Foundation

enum ARRoutePreviewPlanner {
    static func makePlan(
        sampledRoute: [SampledRoutePoint],
        nearestIndex: Int,
        maxDistance: Float,
        maxWaypoints: Int,
        stopAtNextDecision: Bool
    ) -> ARRoutePreviewPlan {
        guard sampledRoute.indices.contains(nearestIndex) else {
            return .empty
        }

        let clampedMaxWaypoints = max(1, maxWaypoints)
        let startIndex = nearestIndex
        let startDistance = sampledRoute[startIndex].cumulativeDistance

        var endIndex = startIndex
        var stopsAtDecision = false

        for index in startIndex..<sampledRoute.count {
            let sampled = sampledRoute[index]
            let distanceAhead = max(0, sampled.cumulativeDistance - startDistance)

            if index > startIndex, stopAtNextDecision, sampled.isTurnHint {
                endIndex = index
                stopsAtDecision = true
                break
            }

            endIndex = index
            if distanceAhead >= maxDistance {
                break
            }
        }

        let pathRouteIndices = Array(startIndex...endIndex)
        let waypointIndices = distributeWaypointIndices(
            along: pathRouteIndices,
            sampledRoute: sampledRoute,
            maxWaypoints: clampedMaxWaypoints
        )

        let waypoints = waypointIndices.map { index in
            let sampled = sampledRoute[index]
            return ARPreviewWaypoint(
                routeIndex: index,
                mapPoint: sampled.mapPoint,
                headingRadians: sampled.headingRadians,
                distanceFromUser: max(0, sampled.cumulativeDistance - startDistance),
                isDecisionPoint: sampled.isTurnHint
            )
        }

        let highlightIndex = waypoints.dropFirst().first?.routeIndex ?? waypoints.first?.routeIndex
        let totalPreviewDistance = max(0, sampledRoute[endIndex].cumulativeDistance - startDistance)

        return ARRoutePreviewPlan(
            pathRouteIndices: pathRouteIndices,
            waypoints: waypoints,
            highlightedRouteIndex: highlightIndex,
            totalPreviewDistance: totalPreviewDistance,
            stopsAtDecision: stopsAtDecision
        )
    }

    private static func distributeWaypointIndices(
        along pathRouteIndices: [Int],
        sampledRoute: [SampledRoutePoint],
        maxWaypoints: Int
    ) -> [Int] {
        guard !pathRouteIndices.isEmpty else { return [] }
        guard pathRouteIndices.count > maxWaypoints else { return pathRouteIndices }

        let firstIndex = pathRouteIndices[0]
        let lastIndex = pathRouteIndices[pathRouteIndices.count - 1]
        let startDistance = sampledRoute[firstIndex].cumulativeDistance
        let endDistance = sampledRoute[lastIndex].cumulativeDistance
        let totalDistance = max(0.001, endDistance - startDistance)

        var selected: [Int] = []
        selected.reserveCapacity(maxWaypoints)

        for slot in 0..<maxWaypoints {
            let t = maxWaypoints == 1 ? 0 : Float(slot) / Float(maxWaypoints - 1)
            let targetDistance = startDistance + totalDistance * t

            let candidate = pathRouteIndices.min { lhs, rhs in
                abs(sampledRoute[lhs].cumulativeDistance - targetDistance)
                    < abs(sampledRoute[rhs].cumulativeDistance - targetDistance)
            } ?? firstIndex

            if selected.last != candidate {
                selected.append(candidate)
            }
        }

        if selected.first != firstIndex {
            selected.insert(firstIndex, at: 0)
        }
        if selected.last != lastIndex {
            selected.append(lastIndex)
        }

        let uniqueSorted = Array(Set(selected)).sorted()
        if uniqueSorted.count <= maxWaypoints {
            return uniqueSorted
        }

        return Array(uniqueSorted.prefix(maxWaypoints - 1)) + [lastIndex]
    }
}
