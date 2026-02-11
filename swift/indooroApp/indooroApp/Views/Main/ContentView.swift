import SwiftUI

struct ContentView: View {
    @StateObject var beaconManager = BeaconManager()
    
    // --- STATES ---
    @State private var searchText = ""
    @State private var targetProduct: Product? = nil
    
    // Maßstab: 25 Pixel pro Meter
    let pixelsPerMeter: Double = 25.0
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                
                // === HAUPT-LAYOUT ===
                VStack(spacing: 0) {
                    
                    // 1. Header
                    HeaderView(
                        userPosition: beaconManager.userPosition,
                        targetProduct: targetProduct,
                        onClearTarget: {
                            withAnimation {
                                targetProduct = nil
                                beaconManager.setTargetProduct(nil) // Pfad löschen
                            }
                        }
                    )
                    .zIndex(1)
                    
                    // 2. Map
                    MapView(
                        beaconManager: beaconManager,
                        pixelsPerMeter: pixelsPerMeter,
                        targetProduct: targetProduct
                    )
                }
                .blur(radius: beaconManager.searchResults.isEmpty ? 0 : 3)
                
                // === SUCHE ===
                VStack {
                    SearchOverlayView(
                        beaconManager: beaconManager,
                        searchText: $searchText,
                        targetProduct: $targetProduct
                    )
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            // WICHTIG: Reagieren auf Änderungen des Ziel-Produkts
            .onChange(of: targetProduct) { newProduct in
                beaconManager.setTargetProduct(newProduct)
            }
        }
    }
}

// Preview für Canvas
#Preview {
    ContentView()
}
