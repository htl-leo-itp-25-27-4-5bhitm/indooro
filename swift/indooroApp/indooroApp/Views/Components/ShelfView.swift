import SwiftUI

struct ShelfView: View {
    let element: LayoutElement
    let pixelsPerMeter: Double
    
    var body: some View {
        let width = CGFloat((element.width ?? 1.0) * pixelsPerMeter)
        let height = CGFloat((element.height ?? 1.0) * pixelsPerMeter)
        let xPos = CGFloat(element.x * pixelsPerMeter + width / 2)
        let yPos = CGFloat(element.y * pixelsPerMeter + height / 2)
        let baseColor = Color(hex: element.color ?? "#D7DCE2")
        let cornerRadius = min(max(min(width, height) * 0.14, 3), 10)
        
        ZStack {
            shelfTile(baseColor: baseColor, cornerRadius: cornerRadius)
            shelfLabel(width: width, height: height)
        }
        .frame(width: width, height: height, alignment: .center)
        .position(x: xPos, y: yPos)
    }

    private func shelfTile(baseColor: Color, cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return ZStack {
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            baseColor.opacity(0.96),
                            baseColor.opacity(0.84)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    shape
                        .strokeBorder(
                            Color.white.opacity(0.5),
                            lineWidth: 0.8
                        )
                )
                .overlay(
                    shape
                        .strokeBorder(
                            Color.black.opacity(0.12),
                            lineWidth: 0.6
                        )
                )

            // subtiler Highlight-Verlauf oben
            shape
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            
            // subtile Abdunklung unten
            shape
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.12)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
        }
        .shadow(color: Color.black.opacity(0.18), radius: 2.4, x: 0, y: 1.6)
        .shadow(color: Color.white.opacity(0.28), radius: 1.2, x: 0, y: -0.6)
    }

    @ViewBuilder
    private func shelfLabel(width: CGFloat, height: CGFloat) -> some View {
        if let label = element.label, !label.isEmpty, width > 16, height > 10 {
            let fontSize = min(max(min(width, height) * 0.22, 7), 9.5)
            
            Text(label)
                .font(.system(size: fontSize, weight: .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 2)
                .frame(width: width)
                .foregroundColor(labelColor(for: element.color))
        }
    }
    
    private func labelColor(for hex: String?) -> Color {
        guard let hex else { return Color.black.opacity(0.68) }
        let raw = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard raw.count == 6, let value = UInt64(raw, radix: 16) else {
            return Color.black.opacity(0.68)
        }
        
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        
        if luminance < 0.45 {
            return Color.white.opacity(0.86)
        }
        return Color.black.opacity(0.7)
    }
}
