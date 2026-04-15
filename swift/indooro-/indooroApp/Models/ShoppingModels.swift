import Foundation
import CoreGraphics

enum ShoppingListItemStatus: String, Codable, CaseIterable, Hashable {
    case open
    case done
    case missing
    case skipped

    var isRoutable: Bool {
        self == .open
    }

    var isCompleted: Bool {
        self == .done || self == .missing || self == .skipped
    }

    var badgeTitle: String {
        switch self {
        case .open:
            return "Offen"
        case .done:
            return "Erledigt"
        case .missing:
            return "Nicht gefunden"
        case .skipped:
            return "Uebersprungen"
        }
    }
}

enum ShoppingRouteMode: String, Codable, CaseIterable {
    case optimized
    case listOrder

    var title: String {
        switch self {
        case .optimized:
            return "Optimiert"
        case .listOrder:
            return "Listenreihenfolge"
        }
    }
}

struct ShoppingListItem: Codable, Identifiable, Hashable {
    let id: UUID
    let productID: Int
    var name: String
    var price: Double
    var layoutCode: String
    var quantity: Int
    var note: String?
    var status: ShoppingListItemStatus
    let addedAt: Date
    var updatedAt: Date

    init(product: Product, quantity: Int = 1) {
        self.id = UUID()
        self.productID = product.id
        self.name = product.name
        self.price = product.price
        self.layoutCode = product.layoutCode
        self.quantity = quantity
        self.note = nil
        self.status = .open
        self.addedAt = Date()
        self.updatedAt = Date()
    }
}

struct ShoppingList: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var items: [ShoppingListItem]
    let createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.items = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isArchived = false
    }

    var openItemCount: Int {
        items.filter { $0.status == .open }.reduce(0) { $0 + $1.quantity }
    }

    var completedItemCount: Int {
        items.filter { $0.status.isCompleted }.reduce(0) { $0 + $1.quantity }
    }
}

struct ShoppingStop: Identifiable, Hashable {
    let id: String
    let shelfID: Int64?
    let title: String
    let mapPoint: CGPoint
    let items: [ShoppingListItem]
    let orderSeed: Date

    var itemIDs: [UUID] {
        items.map(\.id)
    }

    var totalQuantity: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var subtitle: String {
        let articleWord = totalQuantity == 1 ? "Artikel" : "Artikel"
        return "\(totalQuantity) \(articleWord)"
    }

    var itemNamesPreview: String {
        let names = items
            .map(\.name)
            .prefix(2)
            .joined(separator: ", ")
        if items.count > 2 {
            return "\(names) +\(items.count - 2)"
        }
        return names
    }
}

struct ShoppingRouteSnapshot {
    let listID: UUID
    let listName: String
    let routeMode: ShoppingRouteMode
    let orderedStops: [ShoppingStop]
    let unresolvedItems: [ShoppingListItem]
    let completedItems: [ShoppingListItem]

    var currentStop: ShoppingStop? {
        orderedStops.first
    }

    var remainingStopCount: Int {
        orderedStops.count
    }

    var remainingProductCount: Int {
        orderedStops.reduce(0) { $0 + $1.totalQuantity } + unresolvedItems.reduce(0) { $0 + $1.quantity }
    }

    var unresolvedProductCount: Int {
        unresolvedItems.reduce(0) { $0 + $1.quantity }
    }

    var completedProductCount: Int {
        completedItems.reduce(0) { $0 + $1.quantity }
    }
}

struct ShoppingSessionBanner {
    let listName: String
    let currentStopTitle: String
    let remainingStopCount: Int
    let remainingProductCount: Int
    let unresolvedProductCount: Int
}
