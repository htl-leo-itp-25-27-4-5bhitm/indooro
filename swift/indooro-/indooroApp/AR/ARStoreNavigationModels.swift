import Foundation
import simd

enum ARCalibrationSource: String, Sendable {
    case entranceAnchor
    case manualConfirmation
    case liveEstimate
}

struct ARAlignmentSnapshot: Sendable {
    let mapPoint: SIMD2<Float>
    let headingRadians: Float?
    let timestamp: TimeInterval
    let source: ARCalibrationSource
}

struct ARPreviewWaypoint: Sendable {
    let routeIndex: Int
    let mapPoint: SIMD2<Float>
    let headingRadians: Float
    let distanceFromUser: Float
    let isDecisionPoint: Bool
}

struct ARRoutePreviewPlan: Sendable {
    let pathRouteIndices: [Int]
    let waypoints: [ARPreviewWaypoint]
    let highlightedRouteIndex: Int?
    let totalPreviewDistance: Float
    let stopsAtDecision: Bool

    static let empty = ARRoutePreviewPlan(
        pathRouteIndices: [],
        waypoints: [],
        highlightedRouteIndex: nil,
        totalPreviewDistance: 0,
        stopsAtDecision: false
    )

    var isEmpty: Bool {
        pathRouteIndices.isEmpty || waypoints.isEmpty
    }
}

enum ARPresentationState: Equatable {
    case ready
    case blocked(message: String)
}
