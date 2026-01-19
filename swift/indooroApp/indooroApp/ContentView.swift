import SwiftUI

struct ContentView: View {
    @StateObject var beaconManager = BeaconManager()
    
    // Maßstab: ca 23 Pixel pro Meter
    let pixelsPerMeter: Double = 23.0
    
    var body: some View {
        VStack {
            Text("Indooro Map")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            
            // --- KARTE ---
            ZStack(alignment: .topLeading) {
                
                // 1. Hintergrund & Gitter
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .border(Color.black, width: 2)
                
                GridLines(step: pixelsPerMeter, width: 350, height: 500)
                
                // 2. REGALE ZEICHNEN (Ausgelagert in Subview!)
                ForEach(beaconManager.shelves) { element in
                    ShelfView(element: element, pixelsPerMeter: pixelsPerMeter)
                }
                
                // 3. Achsenbeschriftung
                MapAxes(pixelsPerMeter: pixelsPerMeter, width: 350, height: 500)
                
                // 4. BEACONS ZEICHNEN
                ForEach(beaconManager.beacons) { beacon in
                    BeaconMapItem(
                        beacon: beacon,
                        pixelsPerMeter: pixelsPerMeter
                    )
                    .position(
                        x: CGFloat(beacon.positionX * pixelsPerMeter),
                        y: CGFloat(beacon.positionY * pixelsPerMeter)
                    )
                }
            }
            .frame(width: 350, height: 500)
            .background(Color.white)
            .padding()
            
            // --- LISTE ---
            List(beaconManager.beacons) { beacon in
                HStack {
                    Circle()
                        .fill(colorForDistance(beacon.distance))
                        .frame(width: 10, height: 10)
                    
                    VStack(alignment: .leading) {
                        Text(beacon.name).bold()
                        Text("x:\(Int(beacon.positionX)) y:\(Int(beacon.positionY))")
                            .font(.caption2).foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if beacon.distance > 0 {
                        Text(String(format: "%.2f m", beacon.distance))
                            .foregroundColor(.blue)
                            .bold()
                    } else {
                        Text("Suche...")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    func colorForDistance(_ dist: Double) -> Color {
        if dist <= 0 { return .gray }
        if dist < 2.0 { return .green }
        return .orange
    }
}

// MARK: - Subview für Regale (Behebt den Compiler Fehler)
struct ShelfView: View {
    let element: LayoutElement
    let pixelsPerMeter: Double
    
    var body: some View {
        // Berechnungen hier drin machen, damit der Main-Body sauber bleibt
        let width = CGFloat((element.width ?? 1) * pixelsPerMeter)
        let height = CGFloat((element.height ?? 1) * pixelsPerMeter)
        
        // SwiftUI .position setzt den MITTELPUNKT.
        // Deine Daten sind aber Oben-Links. Wir müssen also die Hälfte der Größe addieren.
        let xPos = CGFloat(element.x * pixelsPerMeter) + (width / 2)
        let yPos = CGFloat(element.y * pixelsPerMeter) + (height / 2)
        
        Rectangle()
            .fill(Color(hex: element.color ?? "#CCCCCC"))
            .overlay(
                Text(element.label ?? "")
                    .font(.system(size: 8))
                    .foregroundColor(.black.opacity(0.6))
            )
            .frame(width: width, height: height)
            .position(x: xPos, y: yPos)
    }
}

// MARK: - Beacon Map Icon
struct BeaconMapItem: View {
    let beacon: IndooroBeacon
    let pixelsPerMeter: Double
    
    var statusColor: Color {
        if beacon.distance <= 0 { return .gray.opacity(0.3) }
        if beacon.distance < 2.0 { return .green }
        return .orange
    }
    
    var body: some View {
        ZStack {
            if beacon.distance > 0 {
                Circle()
                    .stroke(statusColor.opacity(0.4), lineWidth: 1)
                    .background(Circle().fill(statusColor.opacity(0.1)))
                    .frame(
                        width: CGFloat(beacon.distance * pixelsPerMeter * 2),
                        height: CGFloat(beacon.distance * pixelsPerMeter * 2)
                    )
            }
            
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundColor(statusColor)
                .background(Circle().fill(.white))
                .shadow(radius: 1)
            
            Text(beacon.name)
                .font(.system(size: 8))
                .offset(y: 12)
        }
    }
}

// MARK: - Achsen
struct MapAxes: View {
    let pixelsPerMeter: Double
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            // X-Achse
            ForEach(0..<15) { meter in
                let xPos = CGFloat(Double(meter) * pixelsPerMeter)
                if xPos <= width {
                    Text("\(meter)")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .position(x: xPos, y: -10)
                }
            }
            // Y-Achse
            ForEach(0..<20) { meter in
                let yPos = CGFloat(Double(meter) * pixelsPerMeter)
                if yPos <= height {
                    Text("\(meter)")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .position(x: -10, y: yPos)
                }
            }
        }
    }
}

// MARK: - Gitter
struct GridLines: View {
    let step: Double
    let width: CGFloat
    let height: CGFloat
    var body: some View {
        Path { path in
            for i in 0..<15 {
                let pos = CGFloat(Double(i) * step)
                path.move(to: CGPoint(x: pos, y: 0))
                path.addLine(to: CGPoint(x: pos, y: height))
            }
            for i in 0..<20 {
                let pos = CGFloat(Double(i) * step)
                path.move(to: CGPoint(x: 0, y: pos))
                path.addLine(to: CGPoint(x: width, y: pos))
            }
        }
        .stroke(Color.gray.opacity(0.2))
    }
}

// MARK: - Helper für Hex-Farben
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
