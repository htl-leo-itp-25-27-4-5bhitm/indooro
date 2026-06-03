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
    private let debugEnabled = true
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
        debugLog("resetSession cachedOpportunities=\(cachedOpportunities.count) activePrompt=\(activePrompt?.opportunityId ?? "nil")")
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

    func clearPrompt(reason: String = "manual") {
        debugLog("clearPrompt reason=\(reason) activePrompt=\(activePrompt?.opportunityId ?? "nil")")
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
            debugLog("preloadPlan skipped reason=session_limit shownCount=\(shownCountForSession)")
            return
        }

        let opportunities = makeOpportunities(
            list: list,
            stops: stops,
            unresolvedItems: unresolvedItems
        )
        debugLog(
            "preloadPlan begin list=\(list.id.uuidString) source=\(source) store=\(storeDebug(store)) stops=\(stops.count) unresolved=\(unresolvedItems.count) opportunities=\(opportunities.map(\.opportunityId))"
        )
        guard !opportunities.isEmpty,
              let urlRequest = makePlanRequest(
                list: list,
                opportunities: opportunities,
                store: store,
                source: source
              ) else {
            debugLog("preloadPlan skipped reason=no_opportunities_or_request")
            return
        }

        let requestID = UUID()
        latestPlanRequestID = requestID
        if planTask != nil {
            debugLog("preloadPlan cancels previous request newRequestId=\(requestID.uuidString)")
        }
        planTask?.cancel()
        isLoading = true
        debugLog("preloadPlan requestId=\(requestID.uuidString) timeout=\(urlRequest.timeoutInterval)s")

        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            Task { @MainActor in
                guard let self else { return }
                guard self.latestPlanRequestID == requestID else {
                    self.debugLog("preloadPlan staleResponse ignored requestId=\(requestID.uuidString)")
                    return
                }
                self.planTask = nil
                self.isLoading = false

                let statusCode = (response as? HTTPURLResponse)?.statusCode
                if let data, let raw = String(data: data, encoding: .utf8) {
                    self.debugLog("preloadPlan rawResponse requestId=\(requestID.uuidString) status=\(statusCode.map(String.init) ?? "nil") body=\(raw)")
                } else {
                    self.debugLog("preloadPlan rawResponse requestId=\(requestID.uuidString) status=\(statusCode.map(String.init) ?? "nil") body=nil")
                }

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
                    self.debugLog("preloadPlan failed requestId=\(requestID.uuidString) error=\(error?.localizedDescription ?? "http_or_decode")")
                    return
                }

                let expiresAt = decoded.expiresAt ?? Date().addingTimeInterval(60)
                let responseSource = decoded.source ?? "unknown"
                self.debugLog(
                    "preloadPlan decoded requestId=\(requestID.uuidString) source=\(responseSource) debug=\(self.debugSummary(decoded.debug)) opportunities=\(decoded.opportunities.map { "\($0.opportunityId):\($0.suggestions.map { $0.product.id })" })"
                )
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
                    self.debugLog("preloadPlan cached key=\(self.keyDebug(key)) suggestions=\(opportunity.suggestions.map { "\($0.product.id):\($0.product.name)" }) expiresAt=\(expiresAt)")
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
        debugLog(
            "showOpportunity requested opportunity=\(opportunityId) source=\(source) store=\(storeDebug(store)) checkedItems=\(checkedItems.map { "\($0.name)#\($0.productID.map(String.init) ?? "nil") upsell=\($0.addedFromUpsell)" })"
        )
        guard let firstTrigger = triggerItems.first,
              let checkedProductId = firstTrigger.productID else {
            debugLog("showOpportunity skipped opportunity=\(opportunityId) reason=no_trigger_items")
            return
        }
        if let blockReason = promptBlockReason(for: checkedProductId) {
            debugLog("showOpportunity skipped opportunity=\(opportunityId) reason=\(blockReason)")
            return
        }

        let key = makePlanKey(
            opportunityId: opportunityId,
            listID: list.id,
            store: store,
            source: source
        )
        guard let cached = cachedOpportunity(for: key) else {
            debugLog("showOpportunity skipped opportunity=\(opportunityId) reason=cache_miss key=\(keyDebug(key)) cachedKeys=\(cachedOpportunities.keys.map(keyDebug))")
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
            debugLog("showOpportunity skipped opportunity=\(opportunityId) reason=no_suggestions_after_filter currentListProductIds=\(Array(currentListProductIds).sorted()) cachedSuggestions=\(cached.response.suggestions.map { $0.product.id })")
            return
        }

        cachedOpportunities[key] = nil
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
        debugLog("showOpportunity activePrompt opportunity=\(opportunityId) checkedProductId=\(checkedProductId) suggestions=\(suggestions.map { "\($0.product.id):\($0.product.name) conf=\($0.confidence)" })")
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

        debugLog("accept suggestion=\(suggestion.product.id):\(suggestion.product.name) prompt=\(prompt?.opportunityId ?? "nil")")
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
            debugLog("dismissCurrentPrompt skipped reason=no_active_prompt suppress=\(suppressProduct)")
            return
        }

        debugLog("dismissCurrentPrompt opportunity=\(prompt.opportunityId) suppress=\(suppressProduct)")
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
            if let body = urlRequest.httpBody,
               let raw = String(data: body, encoding: .utf8) {
                debugLog("preloadPlan requestBody=\(raw)")
            }
            return urlRequest
        } catch {
            debugLog("preloadPlan encodeFailed error=\(error.localizedDescription)")
            return nil
        }
    }

    private func cachedOpportunity(for key: PlanKey) -> CachedOpportunity? {
        guard let cached = cachedOpportunities[key] else {
            debugLog("cache miss key=\(keyDebug(key))")
            return nil
        }
        if cached.expiresAt <= Date() {
            cachedOpportunities[key] = nil
            debugLog("cache expired key=\(keyDebug(key)) expiresAt=\(cached.expiresAt)")
            return nil
        }
        debugLog("cache hit key=\(keyDebug(key)) source=\(cached.responseSource) suggestions=\(cached.response.suggestions.map { $0.product.id })")
        return cached
    }

    private func promptBlockReason(for checkedProductId: Int) -> String? {
        guard activePrompt == nil else {
            return "active_prompt=\(activePrompt?.opportunityId ?? "unknown")"
        }
        guard shownCountForSession < maxPromptsPerSession else {
            return "session_limit shownCount=\(shownCountForSession)"
        }
        guard !dismissedProductIDs.contains(checkedProductId) else {
            return "dismissed_product checkedProductId=\(checkedProductId)"
        }
        if let lastPromptShownAt,
           Date().timeIntervalSince(lastPromptShownAt) < minSecondsBetweenPrompts {
            return "cooldown remaining=\(String(format: "%.2f", minSecondsBetweenPrompts - Date().timeIntervalSince(lastPromptShownAt)))s"
        }
        return nil
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

    private func debugLog(_ message: String) {
        guard debugEnabled else {
            return
        }
        print("[UpsellDebug] \(message)")
    }

    private func keyDebug(_ key: PlanKey) -> String {
        "\(key.opportunityId)|list=\(key.listID.uuidString)|store=\(key.storeId?.uuidString ?? key.storeCode ?? "nil")|source=\(key.source)"
    }

    private func storeDebug(_ store: MobileStoreSummary?) -> String {
        guard let store else {
            return "nil"
        }
        return "\(store.name)#\(store.id.uuidString)#\(store.storeCode)"
    }

    private func debugSummary(_ debug: UpsellPlanDebug?) -> String {
        guard let debug else {
            return "nil"
        }
        return "requestId=\(debug.requestId ?? "nil") model=\(debug.model ?? "nil") source=\(debug.responseSource ?? "nil") elapsedMs=\(debug.elapsedMs.map(String.init) ?? "nil") openAiElapsedMs=\(debug.openAiElapsedMs.map(String.init) ?? "nil") inputTokens=\(debug.inputTokens.map(String.init) ?? "nil") outputTokens=\(debug.outputTokens.map(String.init) ?? "nil") totalTokens=\(debug.totalTokens.map(String.init) ?? "nil") cachedInputTokens=\(debug.cachedInputTokens.map(String.init) ?? "nil") reasoningTokens=\(debug.reasoningTokens.map(String.init) ?? "nil") fallbackReason=\(debug.fallbackReason ?? "nil") opportunities=\(debug.opportunityCount.map(String.init) ?? "nil") candidates=\(debug.candidateCount.map(String.init) ?? "nil")"
    }
}
