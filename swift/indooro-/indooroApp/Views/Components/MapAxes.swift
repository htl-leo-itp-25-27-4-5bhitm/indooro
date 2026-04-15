import SwiftUI

struct MapAxes: View {
    let pixelsPerMeter: Double
    let gridWidth: Int
    let gridHeight: Int
    
    var body: some View {
        ZStack {
            // X-Achse
            ForEach(0...gridWidth, id: \.self) { meter in
                if meter % 2 == 0 { // Nur jeden 2. Meter anzeigen damit es nicht zu voll wird
                    let xPos = CGFloat(Double(meter) * pixelsPerMeter)
                    Text("\(meter)")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .position(x: xPos, y: -10)
                }
            }
            // Y-Achse
            ForEach(0...gridHeight, id: \.self) { meter in
                if meter % 2 == 0 {
                    let yPos = CGFloat(Double(meter) * pixelsPerMeter)
                    Text("\(meter)")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .position(x: -10, y: yPos)
                }
            }
        }
    }
}
