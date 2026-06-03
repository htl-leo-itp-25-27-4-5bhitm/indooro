import Foundation

@MainActor
final class UpsellSuggestionStore: ObservableObject {
    @Published var activePrompt: UpsellPrompt?
    @Published private(set) var isLoading = false

    private struct PlanKey: Hashable {
        let opportunityId: String
        let listID: UUID
        let storeId: UUID?
        let storeCode: String?
        let source: String
    }

    private struct CachedOpportunity {
        let response: UpsellOpportunityResponse
        let responseSource: String
        let expiresAt: Date
    }

    private let apiBase = "https://it220209.cloud.htl-leonding.ac.at/api"
    private let minSecondsBetweenPrompts: TimeInterval = 8
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
    private var planTask: URLSessionDataTask?
    private var latestPlanRequestID = UUID()
    private var cachedOpportunities: [PlanKey: CachedOpportunity] = [:]

    func resetSession() {
        planTask?.cancel()
        planTask = nil
        cachedOpportunities.removeAll()
        activePrompt = nil
        isLoading = false
        latestPlanRequestID = UUID()
        lastPromptShownAt = nil
        shownCountForSession = 0
        dismissedProductIDs.removeAll()
    }

    func clearPrompt() {
        activePrompt = nil
    }

    static func stationOpportunityId(for stop: ShoppingStop) -> String {
        "station:\(stop.id)"
    }

    static func itemOpportunityId(for item: ShoppingListItem) -> String {
        "item:\(item.id.uuidString)"
    }

    func preloadPlan(
        for list: ShoppingList,
        stops: [ShoppingStop],
        unresolvedItems: [ShoppingListItem] = [],
        store: MobileStoreSummary?,
        source: String
    ) {
        guard shownCountForSession < maxPromptsPerSession else {
            return
        }

        let opportunities = makeOpportunities(
            list: list,
            stops: stops,
            unresolvedItems: unresolvedItems
        )
        guard !opportunities.isEmpty,
              let urlRequest = makePlanRequest(
                list: list,
                opportunities: opportunities,
                store: store,
                source: source
              ) else {
            return
        }

        let requestID = UUID()
        latestPlanRequestID = requestID
        planTask?.cancel()
        isLoading = true

        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            Task { @MainActor in
                guard let self, self.latestPlanRequestID == requestID else { return }
                self.planTask = nil
                self.isLoading = false

                guard error == nil,
                      let httpResponse = response as? HTTPURLResponse,
                      (200..<300).contains(httpResponse.statusCode),
                      let data,
                      let decoded = try? self.decoder.decode(UpsellPlanResponse.self, from: data) else {
                    self.reportEvent(
                        eventType: "failed",
                        checkedProductId: nil,
                        suggestedProductId: nil,
                        store: store,
                        source: source,
                        metadataJson: self.metadataJson([
                            "stage": "plan",
                            "reason": error == nil ? "http_or_decode" : "network"
                        ])
                    )
                    return
                }

                let expiresAt = decoded.expiresAt ?? Date().addingTimeInterval(60)
                let responseSource = decoded.source ?? "unknown"
                for opportunity in decoded.opportunities where !opportunity.suggestions.isEmpty {
                    let key = self.makePlanKey(
                        opportunityId: opportunity.opportunityId,
                        listID: list.id,
                        store: store,
                        source: source
                    )
                    self.cachedOpportunities[key] = CachedOpportunity(
                        response: opportunity,
                        responseSource: responseSource,
                        expiresAt: expiresAt
                    )
                }
            }
        }
        planTask = task
        task.resume()
    }

    func showOpportunity(
        opportunityId: String,
        checkedItems: [ShoppingListItem],
        list: ShoppingList,
        store: MobileStoreSummary?,
        source: String
    ) {
        let triggerItems = checkedItems.filter { $0.productID != nil && !$0.addedFromUpsell }
        guard let firstTrigger = triggerItems.first,
              let checkedProductId = firstTrigger.productID,
              canShowPrompt(for: checkedProductId) else {
            return
        }

        let key = makePlanKey(
            opportunityId: opportunityId,
            listID: list.id,
            store: store,
            source: source
        )
        guard let cached = cachedOpportunity(for: key) else {
            return
        }

        let currentListProductIds = Set(list.items.compactMap(\.productID))
        let triggerProductIds = triggerItems.compactMap(\.productID)
        let suggestions = cached.response.suggestions
            .filter { suggestion in
                suggestion.confidence >= minConfidence &&
                !currentListProductIds.contains(suggestion.product.id) &&
                !dismissedProductIDs.contains(suggestion.product.id)
            }
            .prefix(maxSuggestionsShown)

        guard !suggestions.isEmpty else {
            return
        }

        activePrompt = UpsellPrompt(
            opportunityId: opportunityId,
            checkedProductId: checkedProductId,
            checkedProductName: displayName(for: triggerItems),
            triggerProductIds: triggerProductIds,
            listID: list.id,
            store: store,
            source: source,
            suggestions: Array(suggestions)
        )
        lastPromptShownAt = Date()
        shownCountForSession += 1
        reportEvent(
            eventType: "shown",
            checkedProductId: checkedProductId,
            suggestedProductId: nil,
            store: store,
            source: source,
            metadataJson: metadataJson([
                "opportunityId": opportunityId,
                "triggerProductIds": triggerProductIds.map(String.init).joined(separator: ","),
                "responseSource": cached.responseSource,
                "preloaded": "true"
            ])
        )
    }

    func accept(_ suggestion: UpsellSuggestion, prompt: UpsellPrompt?) {
        let metadata: String?
        if let prompt {
            metadata = metadataJson([
                "opportunityId": prompt.opportunityId,
                "triggerProductIds": prompt.triggerProductIds.map(String.init).joined(separator: ",")
            ])
        } else {
            metadata = nil
        }

        reportEvent(
            eventType: "accepted",
            checkedProductId: prompt?.checkedProductId,
            suggestedProductId: suggestion.product.id,
            store: prompt?.store,
            source: prompt?.source,
            metadataJson: metadata
        )
        activePrompt = nil
    }

    func dismissCurrentPrompt(suppressProduct: Bool = false) {
        guard let prompt = activePrompt else {
            return
        }

        if suppressProduct {
            dismissedProductIDs.formUnion(prompt.triggerProductIds)
            reportDismissal(prompt: prompt)
        }

        reportEvent(
            eventType: suppressProduct ? "suppressed" : "dismissed",
            checkedProductId: prompt.checkedProductId,
            suggestedProductId: nil,
            store: prompt.store,
            source: prompt.source,
            metadataJson: metadataJson([
                "opportunityId": prompt.opportunityId,
                "triggerProductIds": prompt.triggerProductIds.map(String.init).joined(separator: ",")
            ])
        )
        activePrompt = nil
    }

    private func makeOpportunities(
        list: ShoppingList,
        stops: [ShoppingStop],
        unresolvedItems: [ShoppingListItem]
    ) -> [UpsellOpportunityRequest] {
        var opportunities: [UpsellOpportunityRequest] = []

        for stop in stops {
            let items = eligibleTriggerItems(stop.items)
            guard !items.isEmpty else { continue }
            opportunities.append(UpsellOpportunityRequest(
                opportunityId: Self.stationOpportunityId(for: stop),
                triggerProductIds: items.compactMap(\.productID),
                triggerProductNames: items.map(\.name)
            ))
        }

        let itemLevelInputs = stops.isEmpty
            ? list.items.filter { $0.status == .open }
            : unresolvedItems

        for item in eligibleTriggerItems(itemLevelInputs) {
            guard let productID = item.productID else { continue }
            opportunities.append(UpsellOpportunityRequest(
                opportunityId: Self.itemOpportunityId(for: item),
                triggerProductIds: [productID],
                triggerProductNames: [item.name]
            ))
        }

        return opportunities
    }

    private func eligibleTriggerItems(_ items: [ShoppingListItem]) -> [ShoppingListItem] {
        items.filter { item in
            guard let productID = item.productID else { return false }
            return !item.addedFromUpsell && !dismissedProductIDs.contains(productID)
        }
    }

    private func makePlanRequest(
        list: ShoppingList,
        opportunities: [UpsellOpportunityRequest],
        store: MobileStoreSummary?,
        source: String
    ) -> URLRequest? {
        guard let url = URL(string: "\(apiBase)/mobile/upsell/plan") else {
            return nil
        }

        let request = UpsellPlanRequest(
            storeId: store?.id,
            storeCode: store?.storeCode,
            shoppingListId: list.id.uuidString,
            currentListProductIds: list.items.compactMap { item in
                item.status == .open ? item.productID : nil
            },
            completedProductIds: list.items.compactMap { item in
                item.status.isCompleted ? item.productID : nil
            },
            source: source,
            opportunities: opportunities
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 6

        do {
            urlRequest.httpBody = try encoder.encode(request)
            return urlRequest
        } catch {
            return nil
        }
    }

    private func cachedOpportunity(for key: PlanKey) -> CachedOpportunity? {
        guard let cached = cachedOpportunities[key] else {
            return nil
        }
        if cached.expiresAt <= Date() {
            cachedOpportunities[key] = nil
            return nil
        }
        return cached
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

    private func makePlanKey(
        opportunityId: String,
        listID: UUID,
        store: MobileStoreSummary?,
        source: String
    ) -> PlanKey {
        PlanKey(
            opportunityId: opportunityId,
            listID: listID,
            storeId: store?.id,
            storeCode: store?.storeCode.lowercased(),
            source: source
        )
    }

    private func displayName(for items: [ShoppingListItem]) -> String {
        let names = items.map(\.name)
        if names.count <= 2 {
            return names.joined(separator: ", ")
        }
        return "\(names.prefix(2).joined(separator: ", ")) +\(names.count - 2)"
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
