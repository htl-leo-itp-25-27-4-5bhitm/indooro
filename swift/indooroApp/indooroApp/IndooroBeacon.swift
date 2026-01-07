import Foundation
import CoreGraphics

struct IndooroBeacon: Identifiable {
    let id: String // Die UUID oder Mac-Adresse
    let name: String
    var rssiHistory: [Int] = [] // Für den gleitenden Durchschnitt (Story #38)
    var smoothedRssi: Double = 0.0
    var distance: Double = 0.0
    
    // Für Story #39: Die feste Position im Raum (in Metern)
    // Wir nehmen an: 0,0 ist unten links
    var positionX: Double
    var positionY: Double
}