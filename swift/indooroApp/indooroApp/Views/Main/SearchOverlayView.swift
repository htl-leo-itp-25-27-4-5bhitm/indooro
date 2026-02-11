import SwiftUI

struct SearchOverlayView: View {
    @ObservedObject var beaconManager: BeaconManager
    @Binding var searchText: String
    @Binding var targetProduct: Product?
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. SUCHLEISTE
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Produkt suchen...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: searchText) { newValue in
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
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding() // Innenabstand der Suchleiste
            
            // 2. TRENNLINIE (Nur wenn Ergebnisse da sind)
            if !beaconManager.searchResults.isEmpty {
                Divider()
            }
            
            // 3. ERGEBNIS-LISTE
            if !beaconManager.searchResults.isEmpty {
                List(beaconManager.searchResults, id: \.self) { product in
                    ProductSearchRow(product: product) {
                        // Aktion beim Auswählen
                        withAnimation {
                            targetProduct = product
                            searchText = ""
                            beaconManager.clearSearch()
                        }
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .listRowInsets(EdgeInsets()) // Entfernt Standard-Abstände der Liste
                    .listRowSeparator(.hidden)   // Keine Standard-Trennlinien, sieht sauberer aus
                }
                .listStyle(.plain) // WICHTIG: Plain style verhindert graue Hintergründe
                .frame(maxHeight: 400) // Maximale Höhe, damit es nicht den ganzen Screen verdeckt
            }
        }
        .background(Color.white)
        .cornerRadius(15) // Das ganze Ding (Suche + Liste) abrunden
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5) // Schöner Schatten
        .padding(.horizontal) // Abstand zum Bildschirmrand links/rechts
        .padding(.top, 10)    // Abstand nach oben
    }
}
