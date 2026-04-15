import Foundation

struct StabilizedNavigationConfig {
    var beacon = BeaconPositioningConfig()
    var poseFusion = PoseFusionConfig()
    var mapMatcher = MapMatcherConfig()
    var route = RouteStabilityConfig()
    var confidence = ConfidenceConfig()

    static let `default` = StabilizedNavigationConfig()
}

struct BeaconPositioningConfig {
    var updateIntervalSeconds: TimeInterval = 0.18
    var warmupSeconds: TimeInterval = 0.8
    var staleMeasurementSeconds: TimeInterval = 1.25
    var minBeaconCountForSolution: Int = 3
    var minDistanceMeters: Float = 0.35
    var maxDistanceMeters: Float = 18.0
    var pathLossExponent: Float = 2.35
    var solverResidualScaleMeters: Float = 1.15
    var solverDamping: Float = 0.28
}

struct PoseFusionConfig {
    var basePositionSmoothingAlpha: Float = 0.46
    var lowConfidenceSmoothingAlpha: Float = 0.18
    var headingSmoothingAlpha: Float = 0.28
    var maxAcceptedSpeedMetersPerSecond: Float = 3.0
    var staleRadioFixSeconds: TimeInterval = 1.2
    var radioAccuracyForFullTrust: Float = 1.0
    var radioAccuracyForZeroTrust: Float = 8.0
    var maxPredictionWindowSeconds: TimeInterval = 0.45
    var movingVelocityRetentionPerSecond: Float = 0.78
    var stationaryVelocityRetentionPerSecond: Float = 0.12
    var motionPredictionAccelerationThresholdG: Float = 0.05
    var headingPredictionBlendAlpha: Float = 0.2
    var confidenceDecayPerPredictionSecond: Float = 0.38
}

struct MapMatcherConfig {
    var candidateSearchRadius: Float = 2.4
    var maxProjectionDistance: Float = 3.8
    var distanceWeight: Float = 1.0
    var headingWeight: Float = 0.65
    var continuityWeight: Float = 0.8
    var routeBiasWeight: Float = 0.55
    var disconnectedEdgePenalty: Float = 4.5
    var preferredEdgeBonus: Float = 0.45
    var requiredScoreImprovementForDisconnectedSwitch: Float = 1.35
}

struct RouteStabilityConfig {
    var offRouteDistanceMeters: Float = 4.0
    var offRouteHoldSeconds: TimeInterval = 2.5
    var rerouteCooldownSeconds: TimeInterval = 8.0
    var activeSegmentLockDistanceMeters: Float = 1.35
    var decisionUnlockDistanceMeters: Float = 1.6
    var progressBacktrackToleranceMeters: Float = 1.2
    var rerouteRequiresAlternativeEdgeScoreGain: Float = 0.55
    var manualCalibrationTriggersReroute: Bool = true
}

struct ConfidenceConfig {
    var lowThreshold: Float = 0.35
    var recoverThreshold: Float = 0.55
    var minBeaconCountForTracking: Int = 3
}
