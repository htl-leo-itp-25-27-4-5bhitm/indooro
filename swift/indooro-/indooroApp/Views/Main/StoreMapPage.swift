import MapKit
import SwiftUI

struct StoreMapPage: View {
    @ObservedObject var beaconManager: BeaconManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MobileStoreListViewModel()
    @State private var selectedStore: MobileStoreSummary?
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 48.295, longitude: 14.32),
            span: MKCoordinateSpan(latitudeDelta: 0.22, longitudeDelta: 0.48)
        )
    )

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    ForEach(viewModel.storesWithCoordinates) { store in
                        if let coordinate = store.coordinate {
                            Annotation(store.name, coordinate: coordinate) {
                                Button {
                                    selectedStore = store
                                } label: {
                                    Image(systemName: "cart.fill")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(width: 38, height: 38)
                                        .background(Color.accentColor, in: Circle())
                                        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea(edges: .bottom)

                bottomPanel
                    .padding()
            }
            .navigationTitle("Filiale waehlen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schliessen") {
                        dismiss()
                    }
                }
            }
            .task {
                viewModel.loadStores()
            }
            .onChange(of: viewModel.stores) { _, stores in
                fitCamera(to: stores)
            }
        }
    }

    @ViewBuilder
    private var bottomPanel: some View {
        if viewModel.isLoading {
            statusPanel("Stores werden geladen...", systemImage: "arrow.triangle.2.circlepath")
        } else if let errorMessage = viewModel.errorMessage {
            statusPanel(errorMessage, systemImage: "exclamationmark.triangle")
        } else if let selectedStore {
            selectedStorePanel(selectedStore)
        } else if viewModel.storesWithCoordinates.isEmpty {
            statusPanel("Keine Stores mit Koordinaten verfuegbar.", systemImage: "mappin.slash")
        } else {
            statusPanel("\(viewModel.storesWithCoordinates.count) Stores mit echten Koordinaten", systemImage: "mappin.and.ellipse")
        }
    }

    private func selectedStorePanel(_ store: MobileStoreSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(store.name)
                .font(.headline)
                .lineLimit(2)

            Text(store.displayAddress)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                beaconManager.loadStoreLayout(for: store, source: .manual)
                dismiss()
            } label: {
                Label("Store-Layout oeffnen", systemImage: "map")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 8)
    }

    private func statusPanel(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
    }

    private func fitCamera(to stores: [MobileStoreSummary]) {
        let coordinates = stores.compactMap(\.coordinate)
        guard !coordinates.isEmpty else { return }

        let minLat = coordinates.map(\.latitude).min() ?? 48.295
        let maxLat = coordinates.map(\.latitude).max() ?? 48.295
        let minLon = coordinates.map(\.longitude).min() ?? 14.32
        let maxLon = coordinates.map(\.longitude).max() ?? 14.32

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.05, (maxLat - minLat) * 1.8),
            longitudeDelta: max(0.05, (maxLon - minLon) * 1.8)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}
