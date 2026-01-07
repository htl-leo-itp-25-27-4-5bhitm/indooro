import Foundation

class KalmanFilter {
    private var R: Double // Prozessrauschen (Wie schnell bewegt sich der User?)
    private var Q: Double // Messrauschen (Wie schlecht ist das Bluetooth-Signal?)
    private var A: Double = 1.0 // Zustandsvektor
    private var B: Double = 0.0 // Steuereingang
    private var C: Double = 1.0 // Messvektor
    
    private var cov: Double = NaN // Kovarianz (Unsicherheit)
    private var x: Double = NaN // Der geschätzte "echte" Wert (gefiltertes RSSI)

    // Standard-Werte für iBeacons in Innenräumen
    init(processNoise: Double = 0.008, measurementNoise: Double = 0.1) {
        self.R = processNoise
        self.Q = measurementNoise
    }

    func filter(_ measurement: Double) -> Double {
        if x.isNaN {
            x = measurement
            cov = 1.0
            return x
        } else {
            // 1. Vorhersage (Prediction)
            let predX = (A * x) + B
            let predCov = ((A * cov) * A) + R

            // 2. Korrektur (Update)
            let K = predCov * C * (1 / ((C * predCov * C) + Q)) // Kalman Gain
            x = predX + K * (measurement - (C * predX))
            cov = predCov - (K * C * predCov)

            return x
        }
    }
}