import SwiftUI

struct ContentView: View {
    @StateObject var beaconManager = BeaconManager()
    
    // Maßstab: 25 Pixel pro Meter (Kannst du anpassen, wenn du weiter rein/raus zoomen willst)
    let pixelsPerMeter: Double = 25.0
    
    var body: some View {
        NavigationView {
            VStack {
                // --- KOPFZEILE ---
                VStack(spacing: 5) {
                    Text("Indooro Map")
                        .font(.largeTitle)
                        .bold()
                    
                    if let pos = beaconManager.userPosition {
                        Text("📍 Position: \(String(format: "%.1f", pos.x))m / \(String(format: "%.1f", pos.y))m")
                            .font(.headline)
                            .foregroundColor(.blue)
                    } else {
                        Text("📡 Suche Position... (Brauche 3 Signale)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top)
                
                // --- SCROLLBARE KARTE ---
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        
                        // 1. Hintergrund (Dynamische Größe!)
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .border(Color.black, width: 2)
                            .frame(
                                width: CGFloat(beaconManager.gridWidth * pixelsPerMeter),
                                height: CGFloat(beaconManager.gridHeight * pixelsPerMeter)
                            )
                        
                        // 2. Gitterlinien
                        GridLines(
                            step: pixelsPerMeter,
                            width: CGFloat(beaconManager.gridWidth * pixelsPerMeter),
                            height: CGFloat(beaconManager.gridHeight * pixelsPerMeter),
                            gridCountX: Int(beaconManager.gridWidth),
                            gridCountY: Int(beaconManager.gridHeight)
                        )
                        
                        // 3. REGALE
                        ForEach(beaconManager.shelves) { element in
                            ShelfView(element: element, pixelsPerMeter: pixelsPerMeter)
                        }
                        
                        // 4. ACHSEN
                        MapAxes(
                            pixelsPerMeter: pixelsPerMeter,
                            gridWidth: Int(beaconManager.gridWidth),
                            gridHeight: Int(beaconManager.gridHeight)
                        )
                        
                        // 5. BEACONS
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
                        
                        // 6. USER POSITION
                        if let pos = beaconManager.userPosition {
                            UserLocationMarker()
                                .position(
                                    x: CGFloat(pos.x * pixelsPerMeter),
                                    y: CGFloat(pos.y * pixelsPerMeter)
                                )
                                .animation(.easeInOut(duration: 0.5), value: pos)
                        }
                    }
                    .frame(
                        width: CGFloat(beaconManager.gridWidth * pixelsPerMeter),
                        height: CGFloat(beaconManager.gridHeight * pixelsPerMeter)
                    )
                    .padding() // Etwas Abstand zum Rand
                }
                
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
                .frame(height: 200) // Liste begrenzen, damit Map mehr Platz hat
            }
        }
    }
    
    func colorForDistance(_ dist: Double) -> Color {
        if dist <= 0 { return .gray }
        if dist < 2.0 { return .green }
        return .orange
    }
}

// MARK: - SUBVIEWS

struct ShelfView: View {
    let element: LayoutElement
    let pixelsPerMeter: Double
    
    var body: some View {
        let width = CGFloat((element.width ?? 1) * pixelsPerMeter)
        let height = CGFloat((element.height ?? 1) * pixelsPerMeter)
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
            if beacon.distance > 0 && beacon.distance < 10 {
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
                    .frame(
                        width: CGFloat(beacon.distance * pixelsPerMeter * 2),
                        height: CGFloat(beacon.distance * pixelsPerMeter * 2)
                    )
            }
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

struct UserLocationMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 24, height: 24)
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

// Dynamische Gitterlinien
struct GridLines: View {
    let step: Double
    let width: CGFloat
    let height: CGFloat
    let gridCountX: Int
    let gridCountY: Int
    
    var body: some View {
        Path { path in
            // Vertikal
            for i in 0...gridCountX {
                let pos = CGFloat(Double(i) * step)
                path.move(to: CGPoint(x: pos, y: 0))
                path.addLine(to: CGPoint(x: pos, y: height))
            }
            // Horizontal
            for i in 0...gridCountY {
                let pos = CGFloat(Double(i) * step)
                path.move(to: CGPoint(x: 0, y: pos))
                path.addLine(to: CGPoint(x: width, y: pos))
            }
        }
        .stroke(Color.gray.opacity(0.2))
    }
}

// Dynamische Achsen
struct MapAxes: View {
    let pixelsPerMeter: Double
    let gridWidth: Int
    let gridHeight: Int
    
    var body: some View {
        ZStack {
            // X-Achse
            ForEach(0...gridWidth, id: \.self) { meter in
                let xPos = CGFloat(Double(meter) * pixelsPerMeter)
                Text("\(meter)")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                    .position(x: xPos, y: -10)
            }
            // Y-Achse
            ForEach(0...gridHeight, id: \.self) { meter in
                let yPos = CGFloat(Double(meter) * pixelsPerMeter)
                Text("\(meter)")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                    .position(x: -10, y: yPos)
            }
        }
    }
}

// Hex Color Extension (bleibt gleich)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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
