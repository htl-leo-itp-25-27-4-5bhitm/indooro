import SwiftUI

struct GridLines: View {
    let step: Double
    let width: CGFloat
    let height: CGFloat
    let gridCountX: Int
    let gridCountY: Int
    var showsDebugStyle = false

    var body: some View {
        ZStack {
            Path { path in
                for index in 0...gridCountX {
                    let position = CGFloat(Double(index) * step)
                    path.move(to: CGPoint(x: position, y: 0))
                    path.addLine(to: CGPoint(x: position, y: height))
                }

                for index in 0...gridCountY {
                    let position = CGFloat(Double(index) * step)
                    path.move(to: CGPoint(x: 0, y: position))
                    path.addLine(to: CGPoint(x: width, y: position))
                }
            }
            .stroke(
                Color.primary.opacity(showsDebugStyle ? 0.12 : 0.035),
                style: StrokeStyle(
                    lineWidth: showsDebugStyle ? 0.8 : 0.6,
                    dash: showsDebugStyle ? [3, 5] : [2, 12]
                )
            )

            Path { path in
                for index in stride(from: 0, through: gridCountX, by: 4) {
                    let position = CGFloat(Double(index) * step)
                    path.move(to: CGPoint(x: position, y: 0))
                    path.addLine(to: CGPoint(x: position, y: height))
                }

                for index in stride(from: 0, through: gridCountY, by: 4) {
                    let position = CGFloat(Double(index) * step)
                    path.move(to: CGPoint(x: 0, y: position))
                    path.addLine(to: CGPoint(x: width, y: position))
                }
            }
            .stroke(
                Color.primary.opacity(showsDebugStyle ? 0.16 : 0.055),
                style: StrokeStyle(lineWidth: 0.9)
            )
        }
    }
}
