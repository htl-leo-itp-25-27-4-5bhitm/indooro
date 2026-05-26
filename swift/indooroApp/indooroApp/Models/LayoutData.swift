import Foundation
import SwiftUI

struct LayoutData: Codable {
    let shopName: String
    let gridSize: GridSize
    let elements: [LayoutElement]
    let layoutId: String?
    let savedAt: String?
    let exportDate: String?
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
    
    // NEU: Kategorie und Meter direkt aus dem JSON
    let category: String?
    let meter: Int?
    let rotation: Double?
    let accessAngle: Double?
    let locked: Bool?

    var categoryCode: String? {
        guard let category, !category.isEmpty else { return nil }
        if let slashIndex = category.firstIndex(of: "/") {
            return String(category[..<slashIndex])
        }
        return category
    }

    var resolvedMeter: Int? {
        if let meter {
            return meter
        }

        guard let category, let slashIndex = category.firstIndex(of: "/") else { return nil }
        let meterStart = category.index(after: slashIndex)
        guard meterStart < category.endIndex else { return nil }
        return Int(category[meterStart...])
    }
}

struct LayoutHistoryEntry: Codable, Identifiable, Hashable {
    let layoutId: String
    let shopName: String
    let savedAt: String
    let exportDate: String?
    let elementCount: Int

    var id: String { layoutId }
}
