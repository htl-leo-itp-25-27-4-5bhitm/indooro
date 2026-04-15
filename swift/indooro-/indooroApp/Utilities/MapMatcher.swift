import Foundation
import simd

struct MapMatchedPose {
    let rawPosition: SIMD2<Float>
    let snappedPosition: SIMD2<Float>
    let edgeID: Int
    let alongEdgeDistance: Float
    let edgeLength: Float
    let headingRadians: Float
    let distanceToRaw: Float
    let score: Float
    let confidence: Float
    let timestamp: TimeInterval
}

final class MapMatcher {
    private let graph: IndoorGraph
    private let config: MapMatcherConfig

    private var lastMatch: MapMatchedPose?

    init(graph: IndoorGraph, config: MapMatcherConfig) {
        self.graph = graph
        self.config = config
    }

    func resetHistory() {
        lastMatch = nil
    }

    func snapToNearestEdge(point: SIMD2<Float>, floor: Int = 0) -> MapMatchedPose? {
        guard let projection = graph.nearestProjection(
            for: point,
            floor: floor,
            maxDistance: config.maxProjectionDistance
        ) else {
            return nil
        }

        let pose = MapMatchedPose(
            rawPosition: point,
            snappedPosition: projection.projectedPoint,
            edgeID: projection.edgeID,
            alongEdgeDistance: projection.alongEdgeDistance,
            edgeLength: projection.edgeLength,
            headingRadians: projection.headingRadians,
            distanceToRaw: projection.distanceToPoint,
            score: projection.distanceToPoint,
            confidence: 1,
            timestamp: Date().timeIntervalSince1970
        )

        lastMatch = pose
        return pose
    }

    func match(
        pose: FusedPose,
        floor: Int = 0,
        preferredRouteEdgeIDs: Set<Int>
    ) -> MapMatchedPose? {
        var candidates = graph.candidateEdges(
            near: pose.mapPoint,
            floor: floor,
            within: config.candidateSearchRadius
        )

        if candidates.isEmpty {
            candidates = graph.edges.filter { edge in
                guard let from = graph.node(id: edge.from), let to = graph.node(id: edge.to) else {
                    return false
                }
                return from.floor == floor && to.floor == floor
            }
        }

        var bestMatch: MapMatchedPose?

        for edge in candidates {
            guard let projection = graph.project(point: pose.mapPoint, onto: edge),
                  projection.distanceToPoint <= config.maxProjectionDistance else {
                continue
            }

            let score = scoreCandidate(
                projection: projection,
                pose: pose,
                preferredRouteEdgeIDs: preferredRouteEdgeIDs
            )

            let candidate = MapMatchedPose(
                rawPosition: pose.mapPoint,
                snappedPosition: projection.projectedPoint,
                edgeID: edge.id,
                alongEdgeDistance: projection.alongEdgeDistance,
                edgeLength: projection.edgeLength,
                headingRadians: projection.headingRadians,
                distanceToRaw: projection.distanceToPoint,
                score: score,
                confidence: pose.confidence,
                timestamp: pose.timestamp
            )

            if bestMatch == nil || candidate.score < (bestMatch?.score ?? .greatestFiniteMagnitude) {
                bestMatch = candidate
            }
        }

        guard var selected = bestMatch else {
            return nil
        }

        if let previous = lastMatch,
           selected.edgeID != previous.edgeID,
           !graph.areEdgesConnected(previous.edgeID, selected.edgeID),
           let projectedOnPrevious = graph.project(point: pose.mapPoint, onto: previous.edgeID) {

            let previousScore = scoreCandidate(
                projection: projectedOnPrevious,
                pose: pose,
                preferredRouteEdgeIDs: preferredRouteEdgeIDs,
                forceEdgeID: previous.edgeID
            )

            let requiredBestScore = previousScore - config.requiredScoreImprovementForDisconnectedSwitch
            if selected.score > requiredBestScore {
                selected = MapMatchedPose(
                    rawPosition: pose.mapPoint,
                    snappedPosition: projectedOnPrevious.projectedPoint,
                    edgeID: previous.edgeID,
                    alongEdgeDistance: projectedOnPrevious.alongEdgeDistance,
                    edgeLength: projectedOnPrevious.edgeLength,
                    headingRadians: projectedOnPrevious.headingRadians,
                    distanceToRaw: projectedOnPrevious.distanceToPoint,
                    score: previousScore,
                    confidence: pose.confidence,
                    timestamp: pose.timestamp
                )
            }
        }

        lastMatch = selected
        return selected
    }

    private func scoreCandidate(
        projection: IndoorEdgeProjection,
        pose: FusedPose,
        preferredRouteEdgeIDs: Set<Int>,
        forceEdgeID: Int? = nil
    ) -> Float {
        let edgeID = forceEdgeID ?? projection.edgeID

        let distanceComponent = projection.distanceToPoint * config.distanceWeight

        let headingComponent: Float
        if let heading = pose.headingRadians {
            let headingDiff = abs(normalizeAngle(heading - projection.headingRadians))
            headingComponent = (headingDiff / .pi) * config.headingWeight
        } else {
            headingComponent = 0
        }

        let continuityComponent: Float
        if let previous = lastMatch {
            let continuityDistance = simd_length(previous.snappedPosition - projection.projectedPoint)
            var continuityPenalty = continuityDistance * config.continuityWeight
            if !graph.areEdgesConnected(previous.edgeID, edgeID) {
                continuityPenalty += config.disconnectedEdgePenalty
            }
            continuityComponent = continuityPenalty
        } else {
            continuityComponent = 0
        }

        let routeBiasComponent: Float
        if preferredRouteEdgeIDs.isEmpty {
            routeBiasComponent = 0
        } else if preferredRouteEdgeIDs.contains(edgeID) {
            routeBiasComponent = -config.preferredEdgeBonus * config.routeBiasWeight
        } else {
            routeBiasComponent = config.preferredEdgeBonus * config.routeBiasWeight
        }

        return distanceComponent + headingComponent + continuityComponent + routeBiasComponent
    }

    private func normalizeAngle(_ angle: Float) -> Float {
        var value = angle
        while value > .pi {
            value -= 2 * .pi
        }
        while value < -.pi {
            value += 2 * .pi
        }
        return value
    }
}
