import SwiftUI

struct ShelfView: View {
    let element: LayoutElement
    let pixelsPerMeter: Double
    
    var body: some View {
        let width = CGFloat((element.width ?? 1.0) * pixelsPerMeter)
        let height = CGFloat((element.height ?? 1.0) * pixelsPerMeter)
        let xPos = CGFloat(element.x * pixelsPerMeter + width / 2)
        let yPos = CGFloat(element.y * pixelsPerMeter + height / 2)
        
        ZStack {
            Rectangle()
                .fill(Color(hex: element.color ?? "#CCCCCC"))
                .frame(width: width, height: height)
                .overlay(
                    Rectangle()
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )
            
            if let label = element.label {
                Text(label)
                    .font(.system(size: 9))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: width - 4)
                    .foregroundColor(.black.opacity(0.7))
            }
        }
        .rotationEffect(.degrees(element.rotation ?? 0))
        .position(x: xPos, y: yPos)
    }
}
