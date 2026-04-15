import SwiftUI

struct ContentView: View {
    @StateObject var beaconManager = BeaconManager()
    @StateObject private var shoppingListManager = ShoppingListManager()
    @StateObject private var shoppingSessionManager = ShoppingSessionManager()

    @State private var searchText = ""
    @State private var targetProduct: Product? = nil
    @State private var showARRoute = false
    @State private var showLayoutSelector = false
    @State private var showShoppingSheet = false
    @State private var mapScale: Double = 1.0
    @State private var showSettings = false
    @State private var toolbarHeight: CGFloat = 0
    @State private var bottomCardHeight: CGFloat = 0
    @State private var pendingShoppingImportPackage: ShoppingTransferPackage?
    @State private var shoppingImportErrorMessage: String?

    private var activeShoppingSnapshot: ShoppingRouteSnapshot? {
        shoppingSessionManager.snapshot
    }

    private var displayUserPosition: CGPoint? {
        beaconManager.userPosition ?? beaconManager.rawUserPosition
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let availableWidth = max(200, geo.size.width - 48)
                let basePixelsPerMeter = Double(availableWidth) / max(1.0, beaconManager.gridWidth)
                let pixelsPerMeter = basePixelsPerMeter * mapScale

                ZStack {
                    // ── Karte (Vollfläche) ──
                    MapView(
                        beaconManager: beaconManager,
                        pixelsPerMeter: pixelsPerMeter,
                        targetProduct: targetProduct,
                        shoppingStops: activeShoppingSnapshot?.orderedStops ?? [],
                        activeShoppingStopID: activeShoppingSnapshot?.currentStop?.id,
                        showsShoppingSession: activeShoppingSnapshot != nil,
                        topInset: toolbarHeight + 8,
                        bottomInset: bottomCardHeight + 8
                    )

                    // ── Floating UI ──
                    VStack(spacing: 0) {
                        measuredToolbarArea
                        Spacer(minLength: 0)
                        measuredBottomCard
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { syncShoppingSession() }
            .onChange(of: targetProduct, initial: false) { _, newProduct in
                guard !shoppingSessionManager.isActive else { return }
                beaconManager.setTargetProduct(newProduct)
            }
            .onChange(of: beaconManager.layoutRevision) { _, _ in
                if shoppingSessionManager.isActive {
                    syncShoppingSession()
                } else if let targetProduct {
                    beaconManager.setTargetProduct(targetProduct)
                }
            }
            .onChange(of: beaconManager.userPosition) { _, _ in
                guard shoppingSessionManager.isActive else { return }
                syncShoppingSession()
            }
            .onChange(of: beaconManager.rawUserPosition) { _, _ in
                guard shoppingSessionManager.isActive else { return }
                syncShoppingSession()
            }
            .onChange(of: shoppingListManager.revision) { _, _ in
                guard shoppingSessionManager.isActive else { return }
                syncShoppingSession()
            }
            .fullScreenCover(isPresented: $showARRoute) {
                ARRouteContainerView(beaconManager: beaconManager)
            }
            .sheet(isPresented: $showLayoutSelector) {
                LayoutSelectionSheet(beaconManager: beaconManager)
            }
            .sheet(isPresented: $showShoppingSheet) {
                ShoppingListsSheet(
                    listManager: shoppingListManager,
                    sessionManager: shoppingSessionManager,
                    beaconManager: beaconManager,
                    pendingImportPackage: $pendingShoppingImportPackage,
                    importErrorMessage: $shoppingImportErrorMessage,
                    onStartSession: startShoppingSession,
                    onStopSession: stopShoppingSession
                )
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheet(
                    trackingMode: trackingModeBinding,
                    mapScale: $mapScale,
                    tapSetsTarget: Binding(
                        get: { beaconManager.tapSetsTarget },
                        set: { beaconManager.tapSetsTarget = $0 }
                    ),
                    canShowAR: beaconManager.navigationRoute.pointCount >= 2,
                    userPosition: displayUserPosition,
                    onShowAR: {
                        showSettings = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            showARRoute = true
                        }
                    }
                )
                .presentationDetents([.medium])
            }
            .onOpenURL { url in
                handleIncomingShoppingTransfer(url)
            }
        }
    }

    // MARK: - Toolbar Area

    private var measuredToolbarArea: some View {
        toolbarArea.readHeight(into: $toolbarHeight)
    }

    @ViewBuilder
    private var toolbarArea: some View {
        VStack(spacing: 8) {
            // ── Suchleiste ──
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)

                TextField("Produkt suchen...", text: $searchText)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: searchText, initial: false) { _, newValue in
                        if newValue.count > 2 {
                            beaconManager.searchProducts(query: newValue)
                        } else {
                            beaconManager.clearSearch()
                        }
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        beaconManager.clearSearch()
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider().frame(height: 18)

                Button { showSettings = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

            // ── Schnellaktionen (nur ohne aktive Suche) ──
            if beaconManager.searchResults.isEmpty {
                HStack(spacing: 8) {
                    Button { showLayoutSelector = true } label: {
                        HStack(spacing: 4) {
                            if beaconManager.isLoadingLayout {
                                ProgressView().scaleEffect(0.65)
                            } else {
                                Image(systemName: "map")
                            }
                            Text(layoutPillLabel)
                                .lineLimit(1)
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                    }
                    .background(.regularMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.05), radius: 3, y: 1)

                    Button { showShoppingSheet = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "cart")
                            Text(cartPillLabel)
                                .lineLimit(1)
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                    }
                    .background(.regularMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.05), radius: 3, y: 1)

                    Spacer()

                    if beaconManager.isLowConfidence || beaconManager.navigationStatusMessage != nil {
                        Button { beaconManager.calibrateAtCurrentEstimate() } label: {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 6, height: 6)
                                Text("Kalibrieren")
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                        }
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(.orange.opacity(0.3), lineWidth: 1))
                    }
                }
            }

            // ── Suchergebnisse ──
            if !beaconManager.searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(beaconManager.searchResults, id: \.self) { product in
                            ProductSearchRow(
                                product: product,
                                isInShoppingList: shoppingListManager.containsProduct(product),
                                onNavigate: {
                                    navigateToProduct(product)
                                    UIApplication.shared.sendAction(
                                        #selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil
                                    )
                                },
                                onAddToList: { addProductToShoppingList(product) }
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)

                            if product != beaconManager.searchResults.last {
                                Divider().padding(.leading, 14)
                            }
                        }
                    }
                }
                .frame(maxHeight: 340)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Bottom Card

    private var measuredBottomCard: some View {
        bottomCard.readHeight(into: $bottomCardHeight)
    }

    @ViewBuilder
    private var bottomCard: some View {
        if let snapshot = activeShoppingSnapshot {
            ShoppingSessionPanel(
                snapshot: snapshot,
                onOpenList: { showShoppingSheet = true },
                onMarkCurrentStopDone: {
                    shoppingSessionManager.markCurrentStopDone(
                        listManager: shoppingListManager,
                        beaconManager: beaconManager
                    )
                },
                onSkipCurrentStop: {
                    shoppingSessionManager.skipCurrentStop(
                        listManager: shoppingListManager,
                        beaconManager: beaconManager
                    )
                },
                onToggleMode: {
                    shoppingSessionManager.toggleRouteMode(
                        listManager: shoppingListManager,
                        beaconManager: beaconManager
                    )
                }
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if let target = targetProduct {
            targetNavigationCard(target)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            Color.clear
                .frame(height: 0)
        }
    }

    // MARK: - Single Target Card

    @ViewBuilder
    private func targetNavigationCard(_ target: Product) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "location.fill")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(.blue.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(target.name)
                    .font(.subheadline.weight(.semibold))
                Text("Regal \(target.layoutCode)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation { targetProduct = nil }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }

    // MARK: - Pill Labels

    private var layoutPillLabel: String {
        let name = beaconManager.selectedLayoutName
        if name == "Aktuelles Server-Layout" { return "Server-Layout" }
        if name.hasPrefix("Version vom ") { return String(name.dropFirst(12)) }
        return name
    }

    private var cartPillLabel: String {
        if let list = shoppingListManager.selectedList {
            return "\(list.name) (\(list.openItemCount))"
        }
        return "Einkaufsliste"
    }

    // MARK: - Actions

    private var trackingModeBinding: Binding<TrackingMode> {
        Binding(
            get: { beaconManager.trackingMode },
            set: { beaconManager.setTrackingMode($0) }
        )
    }

    private func navigateToProduct(_ product: Product) {
        stopShoppingSession()
        withAnimation {
            targetProduct = product
            searchText = ""
        }
    }

    private func addProductToShoppingList(_ product: Product) {
        let targetListID = shoppingListManager.selectedList?.id
        _ = shoppingListManager.addProduct(product, to: targetListID)
        if shoppingSessionManager.activeListID == targetListID {
            syncShoppingSession()
        }
    }

    private func startShoppingSession(for listID: UUID) {
        shoppingListManager.selectList(listID)
        withAnimation {
            targetProduct = nil
            searchText = ""
        }
        beaconManager.clearSearch()
        shoppingSessionManager.startSession(
            for: listID,
            listManager: shoppingListManager,
            beaconManager: beaconManager
        )
    }

    private func stopShoppingSession() {
        shoppingSessionManager.stopSession(beaconManager: beaconManager)
    }

    private func syncShoppingSession() {
        shoppingSessionManager.sync(
            listManager: shoppingListManager,
            beaconManager: beaconManager
        )
    }

    private func handleIncomingShoppingTransfer(_ url: URL) {
        do {
            pendingShoppingImportPackage = try ShoppingTransferService.loadPackage(from: url)
            shoppingImportErrorMessage = nil
            showShoppingSheet = true
        } catch {
            pendingShoppingImportPackage = nil
            shoppingImportErrorMessage = error.localizedDescription
            showShoppingSheet = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private extension View {
    func readHeight(into binding: Binding<CGFloat>) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: HeightPreferenceKey.self, value: geometry.size.height)
            }
        )
        .onPreferenceChange(HeightPreferenceKey.self) { binding.wrappedValue = $0 }
    }
}
