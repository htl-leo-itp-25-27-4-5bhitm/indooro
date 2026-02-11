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
                
                // === HAUPT-LAYOUT (Header & Karte) ===
                VStack(spacing: 0) {
                    
                    // 1. KOPFZEILE (Nutzt HeaderView.swift)
                    HeaderView(
                        userPosition: beaconManager.userPosition,
                        targetProduct: targetProduct,
                        onClearTarget: { withAnimation { targetProduct = nil } }
                    )
                    .zIndex(1) // Header muss über der Map liegen
                    
                    // 2. SCROLLBARE KARTE (Nutzt MapView.swift)
                    MapView(
                        beaconManager: beaconManager,
                        pixelsPerMeter: pixelsPerMeter,
                        targetProduct: targetProduct
                    )
                }
                .blur(radius: beaconManager.searchResults.isEmpty ? 0 : 3) // Hintergrund weichzeichnen bei Suche
                
                // === SUCHE OVERLAY (Nutzt SearchOverlayView.swift) ===
                VStack {
                    // Hier übergeben wir den ganzen Manager und Bindings ($)
                    SearchOverlayView(
                        beaconManager: beaconManager,
                        searchText: $searchText,
                        targetProduct: $targetProduct
                    )
                    
                    Spacer() // Drückt die Suche nach oben
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// Preview für Canvas
#Preview {
    ContentView()
}
