import Foundation

@MainActor
final class UpsellSuggestionStore: ObservableObject {
    @Published var activePrompt: UpsellPrompt?
    @Published private(set) var isLoading = false

    private struct CacheKey: Hashable {
        let checkedProductId: Int
        let listID: UUID
        let storeId: UUID?
        let storeCode: String?
        let source: String
        let currentProductIds: [Int]
        let completedProductIds: [Int]
    }

    private struct PendingContext {
        let requestID: UUID
        let cacheKey: CacheKey
        let checkedProductId: Int
        let checkedProductName: String
        let listID: UUID
        let store: MobileStoreSummary?
        let source: String
        let currentListProductIds: Set<Int>
    }

    private struct CachedResponse {
        let response: UpsellSuggestionResponse
        let expiresAt: Date
    }

    private let apiBase = "https://it220209.cloud.htl-leonding.ac.at/api"
    private let minSecondsBetweenPrompts: TimeInterval = 45
    private let maxPromptsPerSession = 4
    private let maxSuggestionsShown = 3
    private let maxPreloadItems = 3
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
    private var activeDisplayTask: URLSessionDataTask?
    private var preloadTasks: [CacheKey: URLSessionDataTask] = [:]
    private var preloadedResponses: [CacheKey: CachedResponse] = [:]

    func resetSession() {
        activeDisplayTask?.cancel()
        preloadTasks.values.forEach { $0.cancel() }
        activeDisplayTask = nil
        preloadTasks.removeAll()
        preloadedResponses.removeAll()
        activePrompt = nil
        isLoading = false
        latestRequestID = UUID()
        lastPromptShownAt = nil
        shownCountForSession = 0
        dismissedProductIDs.removeAll()
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
        guard let checkedProductId = checkedItem.productID,
              canShowPrompt(for: checkedProductId) else {
            return
        }

        let cacheKey = makeCacheKey(
            checkedProductId: checkedProductId,
            list: list,
            store: store,
            source: source
        )
        let context = PendingContext(
            requestID: UUID(),
            cacheKey: cacheKey,
            checkedProductId: checkedProductId,
            checkedProductName: checkedItem.name,
            listID: list.id,
            store: store,
            source: source,
            currentListProductIds: Set(list.items.compactMap(\.productID))
        )

        latestRequestID = context.requestID
        activeDisplayTask?.cancel()
        activeDisplayTask = nil
        isLoading = false

        if let cached = cachedResponse(for: cacheKey) {
            displayPrompt(from: cached, context: context)
            return
        }

        guard let urlRequest = makeSuggestionsRequest(
            checkedProductId: checkedProductId,
            list: list,
            store: store,
            source: source,
            timeout: 5
        ) else {
            return
        }

        isLoading = true
        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            Task { @MainActor in
                guard let self, self.latestRequestID == context.requestID else { return }
                self.activeDisplayTask = nil
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
                        metadataJson: self.metadataJson([
                            "stage": "display",
                            "reason": error == nil ? "http" : "network"
                        ])
                    )
                    return
                }

                do {
                    let response = try self.decoder.decode(UpsellSuggestionResponse.self, from: data)
                    self.preloadedResponses[cacheKey] = CachedResponse(
                        response: response,
                        expiresAt: response.expiresAt ?? Date().addingTimeInterval(60)
                    )
                    self.displayPrompt(from: response, context: context)
                } catch {
                    self.reportEvent(
                        eventType: "failed",
                        checkedProductId: checkedProductId,
                        suggestedProductId: nil,
                        store: store,
                        source: source,
                        metadataJson: self.metadataJson([
                            "stage": "display",
                            "reason": "decode"
                        ])
                    )
                }
            }
        }
        activeDisplayTask = task
        task.resume()
    }

    func preloadSuggestions(
        for items: [ShoppingListItem],
        list: ShoppingList,
        store: MobileStoreSummary?,
        source: String
    ) {
        guard shownCountForSession < maxPromptsPerSession else {
            return
        }

        let eligibleItems = items
            .filter { item in
                guard let productID = item.productID else { return false }
                return !dismissedProductIDs.contains(productID)
            }
            .prefix(maxPreloadItems)

        for item in eligibleItems {
            guard let checkedProductId = item.productID else { continue }
            let cacheKey = makeCacheKey(
                checkedProductId: checkedProductId,
                list: list,
                store: store,
                source: source
            )
            guard cachedResponse(for: cacheKey) == nil,
                  preloadTasks[cacheKey] == nil,
                  let urlRequest = makeSuggestionsRequest(
                    checkedProductId: checkedProductId,
                    list: list,
                    store: store,
                    source: source,
                    timeout: 6
                  ) else {
                continue
            }

            let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
                Task { @MainActor in
                    guard let self else { return }
                    self.preloadTasks[cacheKey] = nil

                    guard error == nil,
                          let httpResponse = response as? HTTPURLResponse,
                          (200..<300).contains(httpResponse.statusCode),
                          let data,
                          let decoded = try? self.decoder.decode(UpsellSuggestionResponse.self, from: data),
                          !decoded.suggestions.isEmpty else {
                        return
                    }

                    self.preloadedResponses[cacheKey] = CachedResponse(
                        response: decoded,
                        expiresAt: decoded.expiresAt ?? Date().addingTimeInterval(60)
                    )
                }
            }
            preloadTasks[cacheKey] = task
            task.resume()
        }
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

    private func displayPrompt(from response: UpsellSuggestionResponse, context: PendingContext) {
        guard latestRequestID == context.requestID,
              response.checkedProductId == context.checkedProductId,
              canShowPrompt(for: context.checkedProductId) else {
            return
        }

        let suggestions = response.suggestions
            .filter { suggestion in
                suggestion.confidence >= minConfidence &&
                !context.currentListProductIds.contains(suggestion.product.id)
            }
            .prefix(maxSuggestionsShown)

        guard !suggestions.isEmpty else {
            return
        }

        activePrompt = UpsellPrompt(
            checkedProductId: context.checkedProductId,
            checkedProductName: context.checkedProductName,
            listID: context.listID,
            store: context.store,
            source: context.source,
            suggestions: Array(suggestions)
        )
        lastPromptShownAt = Date()
        shownCountForSession += 1
        reportEvent(
            eventType: "shown",
            checkedProductId: context.checkedProductId,
            suggestedProductId: nil,
            store: context.store,
            source: context.source,
            metadataJson: metadataJson([
                "responseSource": response.source ?? "unknown",
                "preloaded": response.source == "cache" ? "backend_cache" : "local_or_network"
            ])
        )
    }

    private func cachedResponse(for key: CacheKey) -> UpsellSuggestionResponse? {
        guard let cached = preloadedResponses[key] else {
            return nil
        }
        if cached.expiresAt <= Date() {
            preloadedResponses[key] = nil
            return nil
        }
        return cached.response
    }

    private func canShowPrompt(for checkedProductId: Int) -> Bool {
        guard activePrompt == nil else {
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

    private func makeSuggestionsRequest(
        checkedProductId: Int,
        list: ShoppingList,
        store: MobileStoreSummary?,
        source: String,
        timeout: TimeInterval
    ) -> URLRequest? {
        guard let url = URL(string: "\(apiBase)/mobile/upsell/suggestions") else {
            return nil
        }

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
            recipeId: list.items.first(where: { $0.productID == checkedProductId })?.sourceRecipeId
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = timeout

        do {
            urlRequest.httpBody = try encoder.encode(request)
            return urlRequest
        } catch {
            return nil
        }
    }

    private func makeCacheKey(
        checkedProductId: Int,
        list: ShoppingList,
        store: MobileStoreSummary?,
        source: String
    ) -> CacheKey {
        let currentProductIds = list.items.compactMap { item -> Int? in
            guard item.status == .open,
                  item.productID != checkedProductId else {
                return nil
            }
            return item.productID
        }
        let completedProductIds = list.items.compactMap { item -> Int? in
            guard item.status.isCompleted,
                  item.productID != checkedProductId else {
                return nil
            }
            return item.productID
        } + [checkedProductId]

        return CacheKey(
            checkedProductId: checkedProductId,
            listID: list.id,
            storeId: store?.id,
            storeCode: store?.storeCode.lowercased(),
            source: source,
            currentProductIds: Array(Set(currentProductIds)).sorted(),
            completedProductIds: Array(Set(completedProductIds)).sorted()
        )
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

    private func metadataJson(_ values: [String: String]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: values, options: [.sortedKeys]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
