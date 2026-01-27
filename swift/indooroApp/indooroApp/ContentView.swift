import SwiftUI

struct ContentView: View {
    @StateObject var beaconManager = BeaconManager()
    
    // Maßstab: ca 23 Pixel pro Meter (angepasst an Screen-Breite / 15m Ladenbreite)
    let pixelsPerMeter: Double = 23.0
    
    var body: some View {
        VStack {
            Text("Indooro Map")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            
            // --- KOPFZEILE: STATUS ---
            if let pos = beaconManager.userPosition {
                Text("📍 Position: \(String(format: "%.1f", pos.x))m / \(String(format: "%.1f", pos.y))m")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.bottom, 5)
            } else {
                Text("📡 Suche Position... (Brauche 3 Signale)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
            }
            
            // --- DIE KARTE (Koordinatenursprung: Oben Links) ---
            ZStack(alignment: .topLeading) {
                
                // 1. Hintergrund & Rahmen
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .border(Color.black, width: 2)
                
                // 2. Gitterlinien
                GridLines(step: pixelsPerMeter, width: 350, height: 500)
                
                // 3. REGALE (Ausgelagert in Subview gegen Compiler-Fehler)
                ForEach(beaconManager.shelves) { element in
                    ShelfView(element: element, pixelsPerMeter: pixelsPerMeter)
                }
                
                // 4. ACHSENBESCHRIFTUNG
                MapAxes(pixelsPerMeter: pixelsPerMeter, width: 350, height: 500)
                
                // 5. BEACONS (Fest installiert)
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
                
                // 6. USER POSITION (Der bewegliche blaue Punkt - U40)
                if let pos = beaconManager.userPosition {
                    UserLocationMarker()
                        .position(
                            x: CGFloat(pos.x * pixelsPerMeter),
                            y: CGFloat(pos.y * pixelsPerMeter)
                        )
                        .animation(.easeInOut(duration: 0.5), value: pos) // Weiche Bewegung
                }
            }
            .frame(width: 350, height: 500) // Feste Größe der Map
            .background(Color.white)
            .clipped() // Wichtig, damit der Punkt nicht aus dem Rahmen wandert
            .padding()
            
            // --- LISTE DER BEACONS ---
            List(beaconManager.beacons) { beacon in
                HStack {
                    // Kleiner Status-Punkt
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
                        VStack(alignment: .trailing) {
                            Text(String(format: "%.2f m", beacon.distance))
                                .foregroundColor(.blue)
                                .bold()
                            Text("\(beacon.rssi) dBm")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("Suche...")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
    
    // Hilfsfunktion für Listen-Farben
    func colorForDistance(_ dist: Double) -> Color {
        if dist <= 0 { return .gray }
        if dist < 2.0 { return .green }
        return .orange
    }
}

// MARK: - SUBVIEWS (Wichtig für Performance & Compiler)

// 1. Regal-View
struct ShelfView: View {
    let element: LayoutElement
    let pixelsPerMeter: Double
    
    var body: some View {
        // Größe berechnen
        let width = CGFloat((element.width ?? 1) * pixelsPerMeter)
        let height = CGFloat((element.height ?? 1) * pixelsPerMeter)
        
        // Position berechnen (SwiftUI positioniert die Mitte, JSON ist aber Oben-Links)
        let xPos = CGFloat(element.x * pixelsPerMeter) + (width / 2)
        let yPos = CGFloat(element.y * pixelsPerMeter) + (height / 2)
        
        Rectangle()
            .fill(Color(hex: element.color ?? "#CCCCCC"))
            .overlay(
                Text(element.label ?? "")
                    .font(.system(size: 8))
                    .foregroundColor(.black.opacity(0.6))
                    .padding(2)
            )
            .frame(width: width, height: height)
            .position(x: xPos, y: yPos)
    }
}

// 2. Beacon-View
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
            // Optional: Radius-Ring zeichnen (visualisiert die Reichweite)
            if beacon.distance > 0 && beacon.distance < 10 {
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
                    .frame(
                        width: CGFloat(beacon.distance * pixelsPerMeter * 2),
                        height: CGFloat(beacon.distance * pixelsPerMeter * 2)
                    )
            }
            
            // Das Icon selbst
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 14))
                .foregroundColor(statusColor)
                .background(Circle().fill(.white).frame(width: 20, height: 20))
                .shadow(radius: 1)
            
            Text(beacon.name)
                .font(.system(size: 7))
                .offset(y: 12)
        }
    }
}

// 3. User Marker (Blauer Punkt)
struct UserLocationMarker: View {
    var body: some View {
        ZStack {
            // Pulsierender Schein
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 24, height: 24)
            
            // Harter Kern
            Circle()
                .fill(Color.blue)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(radius: 2)
            
            Text("ICH")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.blue)
                .offset(y: -14)
        }
    }
}

// 4. Achsen
struct MapAxes: View {
    let pixelsPerMeter: Double
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            // X-Achse (Oben)
            ForEach(0..<15) { meter in
                let xPos = CGFloat(Double(meter) * pixelsPerMeter)
                if xPos <= width {
                    Text("\(meter)")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .position(x: xPos, y: -10)
                }
            }
            // Y-Achse (Links)
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

// 5. Gitterlinien
struct GridLines: View {
    let step: Double
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Path { path in
            // Vertikal
            for i in 0..<15 {
                let pos = CGFloat(Double(i) * step)
                path.move(to: CGPoint(x: pos, y: 0))
                path.addLine(to: CGPoint(x: pos, y: height))
            }
            // Horizontal
            for i in 0..<20 {
                let pos = CGFloat(Double(i) * step)
                path.move(to: CGPoint(x: 0, y: pos))
                path.addLine(to: CGPoint(x: width, y: pos))
            }
        }
        .stroke(Color.gray.opacity(0.2))
    }
}

// 6. Hex-Color Extension
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
