import Foundation

@MainActor
final class UpsellSuggestionStore: ObservableObject {
    @Published var activePrompt: UpsellPrompt?
    @Published private(set) var isLoading = false

    private let apiBase = "https://it220209.cloud.htl-leonding.ac.at/api"
    private let minSecondsBetweenPrompts: TimeInterval = 45
    private let maxPromptsPerSession = 4
    private let maxSuggestionsShown = 3
    private let minConfidence = 0.45
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    private let encoder = JSONEncoder()

    private var lastPromptShownAt: Date?
    private var shownCountForSession = 0
    private var dismissedProductIDs: Set<Int> = []
    private var latestRequestID = UUID()

    func resetSession() {
        activePrompt = nil
        isLoading = false
        latestRequestID = UUID()
        lastPromptShownAt = nil
        shownCountForSession = 0
    }

    func clearPrompt() {
        activePrompt = nil
    }

    func requestSuggestions(
        checkedItem: ShoppingListItem,
        list: ShoppingList,
        store: MobileStoreSummary?,
        source: String
    ) {
        guard let checkedProductId = checkedItem.productID else {
            return
        }
        guard canRequestPrompt(for: checkedProductId) else {
            return
        }
        guard let url = URL(string: "\(apiBase)/mobile/upsell/suggestions") else {
            return
        }

        let requestID = UUID()
        latestRequestID = requestID
        isLoading = true

        let request = UpsellRequest(
            storeId: store?.id,
            storeCode: store?.storeCode,
            checkedProductId: checkedProductId,
            shoppingListId: list.id.uuidString,
            currentListProductIds: list.items.compactMap { item in
                item.status == .open ? item.productID : nil
            },
            completedProductIds: list.items.compactMap { item in
                item.status.isCompleted ? item.productID : nil
            },
            source: source,
            recipeId: checkedItem.sourceRecipeId
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 5

        do {
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            Task { @MainActor in
                guard let self, self.latestRequestID == requestID else { return }
                self.isLoading = false

                guard error == nil,
                      let httpResponse = response as? HTTPURLResponse,
                      (200..<300).contains(httpResponse.statusCode),
                      let data else {
                    self.reportEvent(
                        eventType: "failed",
                        checkedProductId: checkedProductId,
                        suggestedProductId: nil,
                        store: store,
                        source: source,
                        metadataJson: nil
                    )
                    return
                }

                do {
                    let response = try self.decoder.decode(UpsellSuggestionResponse.self, from: data)
                    let suggestions = response.suggestions
                        .filter { $0.confidence >= self.minConfidence }
                        .prefix(self.maxSuggestionsShown)
                    guard !suggestions.isEmpty, self.canRequestPrompt(for: checkedProductId) else {
                        return
                    }

                    self.activePrompt = UpsellPrompt(
                        checkedProductId: checkedProductId,
                        checkedProductName: checkedItem.name,
                        listID: list.id,
                        store: store,
                        source: source,
                        suggestions: Array(suggestions)
                    )
                    self.lastPromptShownAt = Date()
                    self.shownCountForSession += 1
                    self.reportEvent(
                        eventType: "shown",
                        checkedProductId: checkedProductId,
                        suggestedProductId: nil,
                        store: store,
                        source: source,
                        metadataJson: nil
                    )
                } catch {
                    self.reportEvent(
                        eventType: "failed",
                        checkedProductId: checkedProductId,
                        suggestedProductId: nil,
                        store: store,
                        source: source,
                        metadataJson: nil
                    )
                }
            }
        }.resume()
    }

    func accept(_ suggestion: UpsellSuggestion, prompt: UpsellPrompt?) {
        reportEvent(
            eventType: "accepted",
            checkedProductId: prompt?.checkedProductId,
            suggestedProductId: suggestion.product.id,
            store: prompt?.store,
            source: prompt?.source,
            metadataJson: nil
        )
        activePrompt = nil
    }

    func dismissCurrentPrompt(suppressProduct: Bool = false) {
        guard let prompt = activePrompt else {
            return
        }

        if suppressProduct {
            dismissedProductIDs.insert(prompt.checkedProductId)
            reportDismissal(prompt: prompt)
        }

        reportEvent(
            eventType: suppressProduct ? "suppressed" : "dismissed",
            checkedProductId: prompt.checkedProductId,
            suggestedProductId: nil,
            store: prompt.store,
            source: prompt.source,
            metadataJson: nil
        )
        activePrompt = nil
    }

    private func canRequestPrompt(for checkedProductId: Int) -> Bool {
        guard activePrompt == nil, !isLoading else {
            return false
        }
        guard shownCountForSession < maxPromptsPerSession else {
            return false
        }
        guard !dismissedProductIDs.contains(checkedProductId) else {
            return false
        }
        if let lastPromptShownAt,
           Date().timeIntervalSince(lastPromptShownAt) < minSecondsBetweenPrompts {
            return false
        }
        return true
    }

    private func reportEvent(
        eventType: String,
        checkedProductId: Int?,
        suggestedProductId: Int?,
        store: MobileStoreSummary?,
        source: String?,
        metadataJson: String?
    ) {
        guard let url = URL(string: "\(apiBase)/mobile/upsell/events") else {
            return
        }

        let request = UpsellEventRequest(
            eventType: eventType,
            checkedProductId: checkedProductId,
            suggestedProductId: suggestedProductId,
            storeId: store?.id,
            storeCode: store?.storeCode,
            sessionId: nil,
            source: source,
            metadataJson: metadataJson
        )
        sendBestEffort(request, to: url)
    }

    private func reportDismissal(prompt: UpsellPrompt) {
        guard let url = URL(string: "\(apiBase)/mobile/upsell/dismiss") else {
            return
        }

        let request = UpsellDismissRequest(
            checkedProductId: prompt.checkedProductId,
            suggestedProductId: nil,
            storeId: prompt.store?.id,
            storeCode: prompt.store?.storeCode,
            sessionId: nil,
            suppressMinutes: 24 * 60
        )
        sendBestEffort(request, to: url)
    }

    private func sendBestEffort<T: Encodable>(_ request: T, to url: URL) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 3

        do {
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            return
        }

        URLSession.shared.dataTask(with: urlRequest).resume()
    }
}
