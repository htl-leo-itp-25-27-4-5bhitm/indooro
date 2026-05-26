import Foundation

struct IndooroBeacon: Identifiable {
    let id: String
    let name: String
    var rssi: Int = 0
    var distance: Double = 0.0
    
    // Für die Map (User Story #39)
    var positionX: Double
    var positionY: Double
}
