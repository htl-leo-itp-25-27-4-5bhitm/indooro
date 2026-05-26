import SwiftUI

struct MapAxes: View {
    let pixelsPerMeter: Double
    let gridWidth: Int
    let gridHeight: Int

    var body: some View {
        ZStack {
            ForEach(0...gridWidth, id: \.self) { meter in
                if meter.isMultiple(of: 2) {
                    let xPosition = CGFloat(Double(meter) * pixelsPerMeter)
                    Text("\(meter)")
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial, in: Capsule())
                        .position(x: xPosition, y: -12)
                }
            }

            ForEach(0...gridHeight, id: \.self) { meter in
                if meter.isMultiple(of: 2) {
                    let yPosition = CGFloat(Double(meter) * pixelsPerMeter)
                    Text("\(meter)")
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial, in: Capsule())
                        .position(x: -14, y: yPosition)
                }
            }
        }
    }
}
