import Foundation
import simd

enum NavigationMode {
    case tracking
    case manualCalibration
    case lowConfidence
    case reRouting
}

struct NavigationState {
    var mode: NavigationMode = .tracking
    var routeFrozen: Bool = false
    var offRouteSince: TimeInterval?
    var lastRerouteAt: TimeInterval?
    var lastManualCalibrationAt: TimeInterval?
    var statusMessage: String?
}

enum NavigationEvent {
    case sensorUpdate(confidence: Float)
    case manualSetPosition(mapPoint: SIMD2<Float>, timestamp: TimeInterval)
    case manualCalibrationApplied
    case routeDeviationDetected(timestamp: TimeInterval)
    case routeRecovered
    case rerouteFinished(timestamp: TimeInterval)
    case confidenceDrop
    case confidenceRecovered
}

enum NavigationAction {
    case freezeRoute(Bool)
    case runManualCalibration(SIMD2<Float>)
    case triggerReroute
    case publishStatus(String?)
}

final class NavigationStateMachine {
    private(set) var state = NavigationState()
    private let config: ConfidenceConfig

    init(config: ConfidenceConfig) {
        self.config = config
    }

    func handle(_ event: NavigationEvent) -> [NavigationAction] {
        switch event {
        case .sensorUpdate(let confidence):
            if confidence < config.lowThreshold {
                return handle(.confidenceDrop)
            }
            if confidence >= config.recoverThreshold {
                return handle(.confidenceRecovered)
            }
            return []

        case .manualSetPosition(let mapPoint, let timestamp):
            state.mode = .manualCalibration
            state.routeFrozen = true
            state.lastManualCalibrationAt = timestamp
            state.statusMessage = "Manuelle Kalibrierung aktiv"
            return [
                .freezeRoute(true),
                .runManualCalibration(mapPoint),
                .publishStatus(state.statusMessage)
            ]

        case .manualCalibrationApplied:
            state.mode = .tracking
            state.routeFrozen = false
            state.statusMessage = nil
            return [
                .freezeRoute(false),
                .publishStatus(nil)
            ]

        case .routeDeviationDetected(let timestamp):
            guard !state.routeFrozen else {
                return []
            }
            state.mode = .reRouting
            state.lastRerouteAt = timestamp
            state.statusMessage = "Route wird stabil neu berechnet"
            return [
                .triggerReroute,
                .publishStatus(state.statusMessage)
            ]

        case .routeRecovered:
            if state.mode == .reRouting {
                state.mode = .tracking
                state.statusMessage = nil
                return [.publishStatus(nil)]
            }
            return []

        case .rerouteFinished(let timestamp):
            state.mode = .tracking
            state.lastRerouteAt = timestamp
            state.statusMessage = nil
            return [.publishStatus(nil)]

        case .confidenceDrop:
            guard state.mode != .lowConfidence else {
                return []
            }
            state.mode = .lowConfidence
            state.routeFrozen = true
            state.statusMessage = "Signal schwach - Kalibrierung empfohlen"
            return [
                .freezeRoute(true),
                .publishStatus(state.statusMessage)
            ]

        case .confidenceRecovered:
            guard state.mode == .lowConfidence else {
                return []
            }
            state.mode = .tracking
            state.routeFrozen = false
            state.statusMessage = nil
            return [
                .freezeRoute(false),
                .publishStatus(nil)
            ]
        }
    }
}
