import SwiftUI

struct HeaderView: View {
    let userPosition: CGPoint?
    let targetProduct: Product?
    let onClearTarget: () -> Void
    let onOpenProducts: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            topRow
            positionRow
            targetRow
        }
        .padding(14)
        .background(headerBackground)
        .overlay(headerBorder)
        .shadow(color: Color.black.opacity(0.14), radius: 14, y: 8)
    }
    
    private var positionText: String {
        guard let pos = userPosition else {
            return "Position wird ermittelt (mind. 3 Beacons)"
        }
        return "Position: \(String(format: "%.1f", pos.x)) m / \(String(format: "%.1f", pos.y)) m"
    }
    
    private var positionSymbol: String {
        userPosition == nil ? "dot.radiowaves.left.and.right" : "location.fill"
    }
    
    private var positionColor: Color {
        userPosition == nil ? .secondary : .accentColor
    }
    
    private var topRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Indooro")
                    .font(.title2.weight(.semibold))
                
                Text("Indoor Navigation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onOpenProducts) {
                Label("Produkte", systemImage: "square.grid.2x2")
                    .font(.subheadline.weight(.semibold))
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
    }
    
    private var positionRow: some View {
        Label(positionText, systemImage: positionSymbol)
            .font(.caption)
            .foregroundColor(positionColor)
    }
    
    @ViewBuilder
    private var targetRow: some View {
        if let target = targetProduct {
            HStack {
                iconCard(symbol: target.categorySymbol)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(target.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text("\(target.categoryName) • Regal \(target.layoutCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onClearTarget) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(targetBackground)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    private func iconCard(symbol: String) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.accentColor.opacity(0.16))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: symbol)
                    .font(.headline)
                    .foregroundColor(.accentColor)
            )
    }
    
    private var targetBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemBackground))
    }
    
    private var headerBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.ultraThinMaterial)
    }
    
    private var headerBorder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(Color.white.opacity(0.35), lineWidth: 1)
    }
}
