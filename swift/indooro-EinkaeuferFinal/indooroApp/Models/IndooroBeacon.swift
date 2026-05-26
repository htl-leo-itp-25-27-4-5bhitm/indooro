import Foundation

struct IndooroBeacon: Identifiable {
    let id: String
    let name: String
    let beaconUUID: UUID?
    let beaconMajor: UInt16?
    let beaconMinor: UInt16?
    var rssi: Int = 0
    var distance: Double = 0.0
    var lastSeenAt: TimeInterval?
    var measurementQuality: Double = 0.0
    var txPower: Double?

    var positionX: Double
    var positionY: Double
}
