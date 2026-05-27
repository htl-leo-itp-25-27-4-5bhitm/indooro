import Foundation

struct RecipeTag: Codable, Identifiable, Hashable {
    let id: UUID
    let code: String
    let name: String
    let kind: String?
    let status: String?
}

struct RecipeSummary: Codable, Identifiable, Hashable {
    let id: UUID
    let slug: String
    let title: String
    let summary: String?
    let imageUrl: String?
    let servings: Int
    let prepTimeMinutes: Int?
    let cookTimeMinutes: Int?
    let totalTimeMinutes: Int?
    let status: String?
    let publishedAt: String?
    let mappedIngredientCount: Int?
    let totalIngredientCount: Int?
    let tags: [RecipeTag]
}

struct RecipeDetail: Codable, Identifiable, Hashable {
    let id: UUID
    let slug: String
    let title: String
    let summary: String?
    let description: String?
    let imageUrl: String?
    let imageAlt: String?
    let servings: Int
    let prepTimeMinutes: Int?
    let cookTimeMinutes: Int?
    let totalTimeMinutes: Int?
    let status: String?
    let publishedAt: String?
    let archivedAt: String?
    let createdAt: String?
    let updatedAt: String?
    let tags: [RecipeTag]
    let ingredients: [RecipeIngredient]
    let steps: [RecipeStep]
}

struct RecipeIngredient: Codable, Identifiable, Hashable {
    let id: UUID
    let position: Int
    let displayName: String
    let canonicalName: String?
    let quantity: Double?
    let quantityText: String?
    let unitCode: String?
    let unitDisplayName: String?
    let preparationNote: String?
    let optional: Bool

    var amountText: String? {
        if let quantityText, !quantityText.isEmpty {
            if let unitCode, !unitCode.isEmpty {
                return "\(quantityText) \(unitCode)"
            }
            return quantityText
        }
        if let quantity {
            let formatted = quantity.rounded() == quantity ? String(Int(quantity)) : String(quantity)
            if let unitCode, !unitCode.isEmpty {
                return "\(formatted) \(unitCode)"
            }
            return formatted
        }
        return nil
    }

    var quantityTextForList: String? {
        if let quantityText, !quantityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return quantityText
        }
        if let quantity {
            return quantity.rounded() == quantity ? String(Int(quantity)) : String(quantity)
        }
        return nil
    }
}

struct RecipeStep: Codable, Identifiable, Hashable {
    var id: Int { position }
    let position: Int
    let instruction: String
    let durationMinutes: Int?
}

struct RecipeProductMappingResponse: Codable, Hashable {
    let recipeId: UUID
    let storeId: UUID?
    let storeCode: String?
    let ingredients: [RecipeIngredientMappingStatus]
}

struct RecipeIngredientMappingStatus: Codable, Identifiable, Hashable {
    var id: UUID { ingredientId }
    let ingredientId: UUID
    let ingredientName: String
    let status: RecipeMappingState
    let product: MappedRecipeProduct?
    let candidates: [MappedRecipeProduct]
    let confidence: Double?
    let manuallyConfirmed: Bool
    let reason: String?
}

enum RecipeMappingState: String, Codable, Hashable {
    case mapped = "MAPPED"
    case unmapped = "UNMAPPED"
    case multipleCandidates = "MULTIPLE_CANDIDATES"
    case unavailableInStore = "UNAVAILABLE_IN_STORE"
    case productWithoutLayout = "PRODUCT_WITHOUT_LAYOUT"
}

struct MappedRecipeProduct: Codable, Hashable {
    let id: Int
    let name: String
    let price: Double?
    let layoutCode: String?
    let storeId: String?
    let storeCode: String?

    var product: Product? {
        guard let price, let layoutCode, !layoutCode.isEmpty else {
            return nil
        }
        return Product(id: id, name: name, price: price, layoutCode: layoutCode)
    }
}

struct RecipePageResponse<T: Codable>: Codable {
    let content: [T]
    let page: Int
    let size: Int
    let totalElements: Int
}
