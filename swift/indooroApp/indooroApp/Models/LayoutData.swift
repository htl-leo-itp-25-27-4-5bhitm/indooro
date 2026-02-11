import Foundation
import SwiftUI

struct LayoutData: Codable {
    let shopName: String
    let gridSize: GridSize
    let elements: [LayoutElement]
}

struct GridSize: Codable {
    let width: Double
    let height: Double
}

struct LayoutElement: Codable, Identifiable {
    let id: Int64
    let type: String
    let beaconId: String?
    let x: Double
    let y: Double
    let width: Double?
    let height: Double?
    let color: String?
    let label: String?
}
