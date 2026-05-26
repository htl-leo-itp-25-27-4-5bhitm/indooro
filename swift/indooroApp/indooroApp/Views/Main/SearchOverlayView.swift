import SwiftUI

struct SearchOverlayView: View {
    @ObservedObject var beaconManager: BeaconManager
    @Binding var searchText: String
    @Binding var targetProduct: Product?
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                TextField("Produkt suchen", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .focused($isSearchFocused)
                    .onChange(of: searchText) { _, newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.count > 2 {
                            beaconManager.searchProducts(query: trimmed)
                        } else {
                            beaconManager.clearSearch()
                        }
                    }
                
                if beaconManager.isSearching {
                    ProgressView()
                        .controlSize(.small)
                }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        beaconManager.clearSearch()
                        dismissKeyboard()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.15), radius: 12, y: 8)
            
            if shouldShowDropdown {
                VStack(spacing: 10) {
                    if beaconManager.searchResults.isEmpty, beaconManager.isSearching {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Suche läuft…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                    }
                    
                    if !beaconManager.searchResults.isEmpty {
                        resultsList
                    } else if !beaconManager.isSearching, trimmedSearchText.count > 2 {
                        Label("Keine Treffer gefunden", systemImage: "magnifyingglass")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.12), radius: 16, y: 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.26), value: shouldShowDropdown)
    }
    
    private var shouldShowDropdown: Bool {
        beaconManager.isSearching || !beaconManager.searchResults.isEmpty || trimmedSearchText.count > 2
    }
    
    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private var resultsList: some View {
        if beaconManager.searchResults.count <= 3 {
            VStack(spacing: 10) {
                resultRows
            }
            .padding(10)
        } else {
            ScrollView(showsIndicators: true) {
                LazyVStack(spacing: 10) {
                    resultRows
                }
                .padding(10)
            }
            .frame(maxHeight: 280)
        }
    }
    
    @ViewBuilder
    private var resultRows: some View {
        ForEach(beaconManager.searchResults, id: \.id) { product in
            ProductSearchRow(product: product) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    targetProduct = product
                    searchText = ""
                    beaconManager.clearSearch()
                }
                dismissKeyboard()
            }
        }
    }
    
    private func dismissKeyboard() {
        isSearchFocused = false
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
