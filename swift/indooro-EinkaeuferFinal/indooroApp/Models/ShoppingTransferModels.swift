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

    init(item: ShoppingListItem, quantity: Int? = nil) {
        let availableQuantity = max(1, item.quantity)
        self.productID = item.productID
        self.name = item.name
        self.price = item.price
        self.layoutCode = item.layoutCode
        self.quantity = min(availableQuantity, max(1, quantity ?? availableQuantity))
        self.note = item.trimmedNote
        self.status = item.status
    }
}

struct ShoppingShareSelection: Identifiable, Hashable {
    let itemID: UUID
    var quantity: Int

    var id: UUID {
        itemID
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
    init(transferItem: ShoppingTransferItem, sortOrder: Int? = nil) {
        self.id = UUID()
        self.productID = transferItem.productID
        self.name = transferItem.name
        self.price = transferItem.price
        self.layoutCode = transferItem.layoutCode
        self.quantity = max(1, transferItem.quantity)
        let trimmedNote = transferItem.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.note = trimmedNote?.isEmpty == false ? trimmedNote : nil
        self.sortOrder = sortOrder
        self.status = transferItem.status
        self.addedAt = Date()
        self.updatedAt = Date()
    }
}
