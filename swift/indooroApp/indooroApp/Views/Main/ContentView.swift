import SwiftUI

struct ContentView: View {
    @StateObject var beaconManager = BeaconManager()
    
    // --- STATES ---
    @State private var searchText = ""
    @State private var targetProduct: Product? = nil
    
    var body: some View {
        NavigationView {
            // NEU: GeometryReader um die Handybreite zu messen
            GeometryReader { geo in
                
                // Wir berechnen den Maßstab dynamisch (Breite des Screens minus 40px Rand)
                let availableWidth = geo.size.width - 40
                let pixelsPerMeter = Double(availableWidth) / max(1.0, beaconManager.gridWidth)
                
                ZStack(alignment: .top) {
                    
                    // === HAUPT-LAYOUT (Header & Karte) ===
                    VStack(spacing: 0) {
                        
                        // 1. KOPFZEILE
                        HeaderView(
                            userPosition: beaconManager.userPosition,
                            targetProduct: targetProduct,
                            onClearTarget: { withAnimation { targetProduct = nil } }
                        )
                        .zIndex(1)
                        
                        // 2. KARTE (Jetzt mit dynamischem Maßstab)
                        MapView(
                            beaconManager: beaconManager,
                            pixelsPerMeter: pixelsPerMeter,
                            targetProduct: targetProduct
                        )
                    }
                    .blur(radius: beaconManager.searchResults.isEmpty ? 0 : 3)
                    
                    // === SUCHE OVERLAY ===
                    VStack {
                        SearchOverlayView(
                            beaconManager: beaconManager,
                            searchText: $searchText,
                            targetProduct: $targetProduct
                        )
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .onChange(of: targetProduct) { newProduct in
                beaconManager.setTargetProduct(newProduct)
            }
        }
    }
}

#Preview {
    ContentView()
}
