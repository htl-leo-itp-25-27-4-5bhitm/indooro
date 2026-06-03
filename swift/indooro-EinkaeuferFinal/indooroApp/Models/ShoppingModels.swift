import Foundation
import CoreGraphics

private func cleanRecipeIngredientName(
    _ ingredientName: String?,
    quantity: String?,
    unit: String?
) -> String? {
    guard let ingredientName else {
        return nil
    }

    let trimmedName = ingredientName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else {
        return nil
    }

    let amountCandidates = [
        [quantity, unit]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " "),
        quantity?.trimmingCharacters(in: .whitespacesAndNewlines)
    ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .sorted { $0.count > $1.count }

    for amount in amountCandidates {
        let prefix = "\(amount) "
        if trimmedName.range(of: prefix, options: [.anchored, .caseInsensitive]) != nil {
            let start = trimmedName.index(trimmedName.startIndex, offsetBy: prefix.count)
            let cleaned = trimmedName[start...].trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                return cleaned
            }
        }
    }

    return trimmedName
}

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
            return "Übersprungen"
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
    let productID: Int?
    var name: String
    var price: Double?
    var layoutCode: String?
    var quantity: Int
    var note: String?
    var sortOrder: Int?
    var status: ShoppingListItemStatus
    let addedAt: Date
    var updatedAt: Date
    var sourceRecipeId: UUID?
    var sourceRecipeName: String?
    var ingredientName: String?
    var ingredientQuantity: String?
    var ingredientUnit: String?
    var mappingConfidence: Double?
    var manuallyConfirmed: Bool?
    var addedFromUpsell: Bool

    init(
        product: Product,
        quantity: Int = 1,
        note: String? = nil,
        sortOrder: Int? = nil,
        sourceRecipeId: UUID? = nil,
        sourceRecipeName: String? = nil,
        ingredientName: String? = nil,
        ingredientQuantity: String? = nil,
        ingredientUnit: String? = nil,
        mappingConfidence: Double? = nil,
        manuallyConfirmed: Bool? = nil,
        addedFromUpsell: Bool = false
    ) {
        self.id = UUID()
        self.productID = product.id
        self.name = product.name
        self.price = product.price
        self.layoutCode = product.layoutCode
        self.quantity = max(1, quantity)
        self.note = note
        self.sortOrder = sortOrder
        self.status = .open
        self.addedAt = Date()
        self.updatedAt = Date()
        self.sourceRecipeId = sourceRecipeId
        self.sourceRecipeName = sourceRecipeName
        self.ingredientName = ingredientName
        self.ingredientQuantity = ingredientQuantity
        self.ingredientUnit = ingredientUnit
        self.mappingConfidence = mappingConfidence
        self.manuallyConfirmed = manuallyConfirmed
        self.addedFromUpsell = addedFromUpsell
    }

    init(
        freeIngredientName: String,
        quantity: Int = 1,
        note: String? = nil,
        sortOrder: Int? = nil,
        sourceRecipeId: UUID?,
        sourceRecipeName: String?,
        ingredientQuantity: String?,
        ingredientUnit: String?
    ) {
        self.id = UUID()
        self.productID = nil
        self.name = freeIngredientName
        self.price = nil
        self.layoutCode = nil
        self.quantity = max(1, quantity)
        self.note = note
        self.sortOrder = sortOrder
        self.status = .open
        self.addedAt = Date()
        self.updatedAt = Date()
        self.sourceRecipeId = sourceRecipeId
        self.sourceRecipeName = sourceRecipeName
        self.ingredientName = freeIngredientName
        self.ingredientQuantity = ingredientQuantity
        self.ingredientUnit = ingredientUnit
        self.mappingConfidence = nil
        self.manuallyConfirmed = false
        self.addedFromUpsell = false
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case productID
        case name
        case price
        case layoutCode
        case quantity
        case note
        case sortOrder
        case status
        case addedAt
        case updatedAt
        case sourceRecipeId
        case sourceRecipeName
        case ingredientName
        case ingredientQuantity
        case ingredientUnit
        case mappingConfidence
        case manuallyConfirmed
        case addedFromUpsell
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        productID = try container.decodeIfPresent(Int.self, forKey: .productID)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        layoutCode = try container.decodeIfPresent(String.self, forKey: .layoutCode)
        quantity = try container.decode(Int.self, forKey: .quantity)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
        status = try container.decode(ShoppingListItemStatus.self, forKey: .status)
        addedAt = try container.decode(Date.self, forKey: .addedAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        sourceRecipeId = try container.decodeIfPresent(UUID.self, forKey: .sourceRecipeId)
        sourceRecipeName = try container.decodeIfPresent(String.self, forKey: .sourceRecipeName)
        ingredientName = try container.decodeIfPresent(String.self, forKey: .ingredientName)
        ingredientQuantity = try container.decodeIfPresent(String.self, forKey: .ingredientQuantity)
        ingredientUnit = try container.decodeIfPresent(String.self, forKey: .ingredientUnit)
        mappingConfidence = try container.decodeIfPresent(Double.self, forKey: .mappingConfidence)
        manuallyConfirmed = try container.decodeIfPresent(Bool.self, forKey: .manuallyConfirmed)
        addedFromUpsell = try container.decodeIfPresent(Bool.self, forKey: .addedFromUpsell) ?? false
    }

    var effectiveSortOrder: Int {
        sortOrder ?? Int(addedAt.timeIntervalSince1970 * 1000)
    }

    var trimmedNote: String? {
        guard let note else {
            return nil
        }

        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var recipeSourceText: String? {
        guard let sourceRecipeName, !sourceRecipeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let ingredient = cleanRecipeIngredientName(
            ingredientName,
            quantity: ingredientQuantity,
            unit: ingredientUnit
        )
        let amount = [ingredientQuantity, ingredientUnit]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if let ingredient, !ingredient.isEmpty, !amount.isEmpty {
            return "\(sourceRecipeName): \(amount) \(ingredient)"
        }
        if let ingredient, !ingredient.isEmpty {
            return "\(sourceRecipeName): \(ingredient)"
        }
        return sourceRecipeName
    }

    static func sortByListOrder(_ lhs: ShoppingListItem, _ rhs: ShoppingListItem) -> Bool {
        if lhs.effectiveSortOrder == rhs.effectiveSortOrder {
            if lhs.addedAt == rhs.addedAt {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.addedAt < rhs.addedAt
        }

        return lhs.effectiveSortOrder < rhs.effectiveSortOrder
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
    let orderSeed: Int

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
    let totalStopCount: Int
    let totalProductCount: Int

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

    var completedStopCount: Int {
        max(0, totalStopCount - remainingStopCount)
    }

    var currentStopNumber: Int? {
        guard currentStop != nil, totalStopCount > 0 else {
            return nil
        }

        return min(totalStopCount, completedStopCount + 1)
    }

    var progressFraction: Double {
        guard totalProductCount > 0 else {
            return remainingStopCount == 0 ? 1 : 0
        }

        return min(1, max(0, Double(completedProductCount) / Double(totalProductCount)))
    }
}

struct ShoppingSessionBanner {
    let listName: String
    let currentStopTitle: String
    let remainingStopCount: Int
    let remainingProductCount: Int
    let unresolvedProductCount: Int
}
