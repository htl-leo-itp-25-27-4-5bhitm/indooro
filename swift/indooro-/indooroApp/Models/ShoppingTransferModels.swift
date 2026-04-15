import Foundation

enum ShoppingTransferKind: String, Codable, CaseIterable {
    case fullList
    case itemSelection

    var title: String {
        switch self {
        case .fullList:
            return "Komplette Liste"
        case .itemSelection:
            return "Artikelauswahl"
        }
    }
}

struct ShoppingTransferItem: Codable, Hashable {
    let productID: Int
    let name: String
    let price: Double
    let layoutCode: String
    let quantity: Int
    let note: String?
    let status: ShoppingListItemStatus

    init(item: ShoppingListItem) {
        self.productID = item.productID
        self.name = item.name
        self.price = item.price
        self.layoutCode = item.layoutCode
        self.quantity = item.quantity
        self.note = item.note
        self.status = item.status
    }
}

struct ShoppingTransferPackage: Codable, Identifiable {
    static let currentVersion = 1

    let id: UUID
    let version: Int
    let kind: ShoppingTransferKind
    let sourceListID: UUID?
    let sourceListName: String
    let senderDisplayName: String?
    let note: String?
    let exportedAt: Date
    let items: [ShoppingTransferItem]

    init(
        id: UUID = UUID(),
        version: Int = ShoppingTransferPackage.currentVersion,
        kind: ShoppingTransferKind,
        sourceListID: UUID?,
        sourceListName: String,
        senderDisplayName: String? = nil,
        note: String? = nil,
        exportedAt: Date = Date(),
        items: [ShoppingTransferItem]
    ) {
        self.id = id
        self.version = version
        self.kind = kind
        self.sourceListID = sourceListID
        self.sourceListName = sourceListName
        self.senderDisplayName = senderDisplayName
        self.note = note
        self.exportedAt = exportedAt
        self.items = items
    }

    var totalQuantity: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var suggestedImportedListName: String {
        sourceListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Importierte Einkaufsliste"
            : sourceListName
    }
}

extension ShoppingListItem {
    init(transferItem: ShoppingTransferItem) {
        self.id = UUID()
        self.productID = transferItem.productID
        self.name = transferItem.name
        self.price = transferItem.price
        self.layoutCode = transferItem.layoutCode
        self.quantity = transferItem.quantity
        self.note = transferItem.note
        self.status = transferItem.status
        self.addedAt = Date()
        self.updatedAt = Date()
    }
}
