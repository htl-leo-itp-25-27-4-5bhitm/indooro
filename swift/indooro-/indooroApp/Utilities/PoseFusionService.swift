import Foundation
import simd

enum PoseSource {
    case ble
    case ar
    case radio
    case manual
}

struct RawPoseSample {
    let mapPoint: SIMD2<Float>
    let headingRadians: Float?
    let confidence: Float
    let timestamp: TimeInterval
    let source: PoseSource
}

struct RadioFix {
    let mapPoint: SIMD2<Float>
    let accuracyMeters: Float
    let timestamp: TimeInterval
}

struct FusedPose {
    let mapPoint: SIMD2<Float>
    let headingRadians: Float?
    let confidence: Float
    let velocityMetersPerSecond: SIMD2<Float>
    let timestamp: TimeInterval
}

final class PoseFusionService {
    private let config: PoseFusionConfig
    private var lastPose: FusedPose?
    private var lastAbsolutePoseTimestamp: TimeInterval?

    init(config: PoseFusionConfig) {
        self.config = config
    }

    func reset(to mapPoint: SIMD2<Float>? = nil, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        if let mapPoint {
            lastPose = FusedPose(
                mapPoint: mapPoint,
                headingRadians: lastPose?.headingRadians,
                confidence: 1,
                velocityMetersPerSecond: SIMD2<Float>(repeating: 0),
                timestamp: timestamp
            )
            lastAbsolutePoseTimestamp = timestamp
            return
        }

        lastPose = nil
        lastAbsolutePoseTimestamp = nil
    }

    func update(rawPose: RawPoseSample, radioFix: RadioFix?) -> FusedPose {
        let fusedMeasurement = fuse(rawPose: rawPose, radioFix: radioFix)

        guard let previous = lastPose else {
            let initial = FusedPose(
                mapPoint: fusedMeasurement.position,
                headingRadians: rawPose.headingRadians,
                confidence: fusedMeasurement.confidence,
                velocityMetersPerSecond: SIMD2<Float>(repeating: 0),
                timestamp: rawPose.timestamp
            )
            lastPose = initial
            lastAbsolutePoseTimestamp = rawPose.timestamp
            return initial
        }

        let dt = max(1.0 / 30.0, min(1.0, rawPose.timestamp - previous.timestamp))
        let distance = simd_length(fusedMeasurement.position - previous.mapPoint)
        let speed = distance / Float(dt)

        let dynamicAlpha = smoothingAlpha(for: fusedMeasurement.confidence)
        let speedLimitedAlpha: Float
        if speed > config.maxAcceptedSpeedMetersPerSecond {
            speedLimitedAlpha = dynamicAlpha * 0.72
        } else {
            speedLimitedAlpha = dynamicAlpha
        }

        let smoothedPoint = previous.mapPoint + (fusedMeasurement.position - previous.mapPoint) * speedLimitedAlpha

        let heading = blendHeading(
            previous: previous.headingRadians,
            incoming: rawPose.headingRadians,
            alpha: config.headingSmoothingAlpha
        )

        let velocity = (smoothedPoint - previous.mapPoint) / Float(dt)

        let result = FusedPose(
            mapPoint: smoothedPoint,
            headingRadians: heading,
            confidence: fusedMeasurement.confidence,
            velocityMetersPerSecond: velocity,
            timestamp: rawPose.timestamp
        )

        lastPose = result
        lastAbsolutePoseTimestamp = rawPose.timestamp
        return result
    }

    func predict(
        to timestamp: TimeInterval,
        headingRadians: Float?,
        motionIntensityG: Float
    ) -> FusedPose? {
        guard var previous = lastPose,
              let lastAbsolutePoseTimestamp,
              timestamp > previous.timestamp else {
            return lastPose
        }

        let absoluteAge = timestamp - lastAbsolutePoseTimestamp
        guard absoluteAge <= config.maxPredictionWindowSeconds else {
            return lastPose
        }

        let dt = min(Float(timestamp - previous.timestamp), 0.12)
        guard dt > 0 else {
            return previous
        }

        let movementBlend = clamp(
            motionIntensityG / max(0.001, config.motionPredictionAccelerationThresholdG),
            min: 0,
            max: 1
        )
        let retention = lerp(
            config.stationaryVelocityRetentionPerSecond,
            config.movingVelocityRetentionPerSecond,
            t: movementBlend
        )
        let damping = max(0, min(1, pow(retention, dt)))
        var predictedVelocity = previous.velocityMetersPerSecond * damping

        if let headingRadians {
            let speed = simd_length(predictedVelocity)
            if speed > 0.03 {
                let targetDirection = SIMD2<Float>(sin(headingRadians), cos(headingRadians))
                let currentDirection = predictedVelocity / speed
                let mixedDirection = currentDirection * (1 - config.headingPredictionBlendAlpha)
                    + targetDirection * config.headingPredictionBlendAlpha
                let normalizedDirection = normalized(mixedDirection) ?? currentDirection
                predictedVelocity = normalizedDirection * speed
            }
        }

        let predictedPoint = previous.mapPoint + predictedVelocity * dt
        let confidenceDrop = Float(absoluteAge) * config.confidenceDecayPerPredictionSecond
        let predicted = FusedPose(
            mapPoint: predictedPoint,
            headingRadians: blendHeading(
                previous: previous.headingRadians,
                incoming: headingRadians,
                alpha: config.headingSmoothingAlpha
            ),
            confidence: clamp(previous.confidence - confidenceDrop, min: 0.12, max: 1),
            velocityMetersPerSecond: predictedVelocity,
            timestamp: timestamp
        )

        lastPose = predicted
        previous = predicted
        return previous
    }

    private func fuse(rawPose: RawPoseSample, radioFix: RadioFix?) -> (position: SIMD2<Float>, confidence: Float) {
        guard let radioFix,
              rawPose.timestamp - radioFix.timestamp <= config.staleRadioFixSeconds else {
            return (rawPose.mapPoint, clamp(rawPose.confidence, min: 0, max: 1))
        }

        let radioWeight = weightForRadioAccuracy(radioFix.accuracyMeters)
        let rawWeight = 1 - radioWeight

        let fusedPosition = rawPose.mapPoint * rawWeight + radioFix.mapPoint * radioWeight

        let confidence = clamp(
            rawPose.confidence * rawWeight + (1 - normalizeAccuracy(radioFix.accuracyMeters)) * radioWeight,
            min: 0,
            max: 1
        )

        return (fusedPosition, confidence)
    }

    private func smoothingAlpha(for confidence: Float) -> Float {
        let c = clamp(confidence, min: 0, max: 1)
        let low = config.lowConfidenceSmoothingAlpha
        let high = config.basePositionSmoothingAlpha
        return low + (high - low) * c
    }

    private func normalizeAccuracy(_ accuracy: Float) -> Float {
        if accuracy <= config.radioAccuracyForFullTrust {
            return 0
        }
        if accuracy >= config.radioAccuracyForZeroTrust {
            return 1
        }

        return (accuracy - config.radioAccuracyForFullTrust)
            / (config.radioAccuracyForZeroTrust - config.radioAccuracyForFullTrust)
    }

    private func weightForRadioAccuracy(_ accuracy: Float) -> Float {
        let normalized = normalizeAccuracy(accuracy)
        return clamp(1 - normalized, min: 0, max: 0.7)
    }

    private func blendHeading(previous: Float?, incoming: Float?, alpha: Float) -> Float? {
        guard let incoming else {
            return previous
        }
        guard let previous else {
            return incoming
        }

        let delta = normalizeAngle(incoming - previous)
        return normalizeAngle(previous + delta * alpha)
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

    private func clamp(_ value: Float, min: Float, max: Float) -> Float {
        Swift.max(min, Swift.min(max, value))
    }

    private func lerp(_ a: Float, _ b: Float, t: Float) -> Float {
        let clamped = clamp(t, min: 0, max: 1)
        return a + (b - a) * clamped
    }

    private func normalized(_ vector: SIMD2<Float>) -> SIMD2<Float>? {
        let length = simd_length(vector)
        guard length > 0.0001 else {
            return nil
        }

        return vector / length
    }
}
