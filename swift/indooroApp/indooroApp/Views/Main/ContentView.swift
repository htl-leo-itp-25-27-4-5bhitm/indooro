import SwiftUI

struct ContentView: View {
    @StateObject private var beaconManager = BeaconManager()
    @State private var targetProduct: Product? = nil
    @State private var selectedTab: AppTab = .map

    var body: some View {
        TabView(selection: $selectedTab) {
            MapHomeView(
                beaconManager: beaconManager,
                targetProduct: $targetProduct
            )
            .tabItem {
                Label("Karte", systemImage: "map")
            }
            .tag(AppTab.map)

            ProductsCategoriesView(beaconManager: beaconManager) { product in
                withAnimation(.easeInOut(duration: 0.2)) {
                    targetProduct = product
                }
                selectedTab = .map
            }
            .tabItem {
                Label("Produkte", systemImage: "square.grid.2x2")
            }
            .tag(AppTab.products)

            SettingsInfoView(beaconManager: beaconManager)
                .tabItem {
                    Label("Info", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .onChange(of: targetProduct) { _, newProduct in
            beaconManager.setTargetProduct(newProduct)
        }
    }
}

private enum AppTab: Hashable {
    case map
    case products
    case settings
}

#Preview {
    ContentView()
}
