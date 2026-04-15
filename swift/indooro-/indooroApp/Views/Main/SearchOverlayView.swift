import SwiftUI

struct SearchOverlayView: View {
    @ObservedObject var beaconManager: BeaconManager
    @ObservedObject var shoppingListManager: ShoppingListManager
    @Binding var searchText: String
    let onNavigateToProduct: (Product) -> Void
    let onAddProductToList: (Product) -> Void
    let onOpenShoppingList: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 1. SUCHLEISTE
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Produkt suchen...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .onChange(of: searchText, initial: false) { _, newValue in
                        if newValue.count > 2 {
                            beaconManager.searchProducts(query: newValue)
                        } else {
                            beaconManager.clearSearch()
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        beaconManager.clearSearch()
                        // Tastatur schließen
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding() // Innenabstand der Suchleiste

            if let selectedList = shoppingListManager.selectedList {
                HStack(spacing: 8) {
                    Image(systemName: "cart")
                        .foregroundColor(.blue)

                    Text("Liste: \(selectedList.name) (\(selectedList.openItemCount) offen)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Oeffnen") {
                        onOpenShoppingList()
                    }
                    .font(.caption.weight(.semibold))
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            
            // 2. TRENNLINIE (Nur wenn Ergebnisse da sind)
            if !beaconManager.searchResults.isEmpty {
                Divider()
            }
            
            // 3. ERGEBNIS-LISTE
            if !beaconManager.searchResults.isEmpty {
                List(beaconManager.searchResults, id: \.self) { product in
                    ProductSearchRow(
                        product: product,
                        isInShoppingList: shoppingListManager.containsProduct(product),
                        onNavigate: {
                            withAnimation {
                                searchText = ""
                                beaconManager.clearSearch()
                            }
                            onNavigateToProduct(product)
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        },
                        onAddToList: {
                            onAddProductToList(product)
                        }
                    )
                    .listRowInsets(EdgeInsets()) // Entfernt Standard-Abstände der Liste
                    .listRowSeparator(.hidden)   // Keine Standard-Trennlinien, sieht sauberer aus
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain) // WICHTIG: Plain style verhindert graue Hintergründe
                .frame(maxHeight: 400) // Maximale Höhe, damit es nicht den ganzen Screen verdeckt
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(15) // Das ganze Ding (Suche + Liste) abrunden
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5) // Schöner Schatten
        .padding(.horizontal) // Abstand zum Bildschirmrand links/rechts
        .padding(.top, 10)    // Abstand nach oben
    }
}
