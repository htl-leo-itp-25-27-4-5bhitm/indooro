import SwiftUI

struct GridLines: View {
    let step: Double
    let width: CGFloat
    let height: CGFloat
    let gridCountX: Int
    let gridCountY: Int
    
    var body: some View {
        Path { path in
            // Vertikale Linien
            for i in 0...gridCountX {
                let pos = CGFloat(Double(i) * step)
                path.move(to: CGPoint(x: pos, y: 0))
                path.addLine(to: CGPoint(x: pos, y: height))
            }
            // Horizontale Linien
            for i in 0...gridCountY {
                let pos = CGFloat(Double(i) * step)
                path.move(to: CGPoint(x: 0, y: pos))
                path.addLine(to: CGPoint(x: width, y: pos))
            }
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }
}
