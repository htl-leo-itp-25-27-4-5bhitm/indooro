import SwiftUI

struct MapHomeView: View {
    @ObservedObject var beaconManager: BeaconManager
    @Binding var targetProduct: Product?

    @State private var searchText = ""

    var body: some View {
        GeometryReader { geo in
            let availableWidth = max(geo.size.width - 40, 1)
            let pixelsPerMeter = Double(availableWidth) / max(1.0, beaconManager.gridWidth)

            MapView(
                beaconManager: beaconManager,
                pixelsPerMeter: pixelsPerMeter,
                targetProduct: targetProduct
            )
            .blur(radius: mapBlurRadius)
            .animation(.easeInOut(duration: 0.2), value: mapBlurRadius)
            .safeAreaInset(edge: .top, spacing: 8) {
                topInset
            }
            .safeAreaInset(edge: .bottom, spacing: 10) {
                bottomInset
            }
        }
    }

    private var topInset: some View {
        VStack(spacing: 10) {
            topStatusBar

            SearchOverlayView(
                beaconManager: beaconManager,
                searchText: $searchText,
                targetProduct: $targetProduct
            )
        }
        .padding(.horizontal, 14)
    }

    @ViewBuilder
    private var bottomInset: some View {
        if let target = targetProduct {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: target.categorySymbol)
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(target.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(target.categoryName) • Regal \(target.layoutCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(12)
            .background(statusPillBackground)
            .padding(.horizontal, 14)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var topStatusBar: some View {
        HStack(spacing: 8) {
            Label(positionText, systemImage: positionSymbol)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(positionColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(statusPillBackground)

            Spacer()

            if targetProduct != nil {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        targetProduct = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .background(statusPillBackground)
            }
        }
    }

    private var mapBlurRadius: CGFloat {
        if beaconManager.isSearching || !beaconManager.searchResults.isEmpty || trimmedSearchText.count > 2 {
            return 1.2
        }
        return 0
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var positionText: String {
        guard let pos = beaconManager.userPosition else {
            return "Position wird ermittelt"
        }
        return "\(String(format: "%.1f", pos.x)) m / \(String(format: "%.1f", pos.y)) m"
    }

    private var positionSymbol: String {
        beaconManager.userPosition == nil ? "dot.radiowaves.left.and.right" : "location.fill"
    }

    private var positionColor: Color {
        beaconManager.userPosition == nil ? .secondary : .accentColor
    }

    private var statusPillBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.32), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 10, y: 8)
    }
}
