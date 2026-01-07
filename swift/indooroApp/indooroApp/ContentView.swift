import SwiftUI

struct ContentView: View {
    @StateObject var beaconManager = BeaconManager()
    
    // Konfiguration Story #39: Maßstab
    let pixelsPerMeter: Double = 80.0 // Etwas kleiner, damit es aufs Handy passt
    
    var body: some View {
        VStack {
            Text("Indooro Radar")
                .font(.largeTitle)
                .bold()
                .padding()
            
            // --- DIE KARTE (Story #39) ---
            ZStack(alignment: .bottomLeading) {
                // Raum-Hintergrund
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .border(Color.black, width: 2)
                
                // Koordinaten-Gitter (Optional für Optik)
                GridLines()
                
                // Beacons zeichnen
                ForEach(beaconManager.beacons) { beacon in
                    BeaconView(beacon: beacon)
                        .position(
                            x: calculateX(beacon.positionX),
                            y: calculateY(beacon.positionY) // Y muss gedreht werden!
                        )
                }
            }
            .frame(width: 350, height: 400) // Simulierter Raum ca 4.5m x 5m
            .clipped()
            .background(Color.white)
            
            // --- LISTE (Debug Info für Story #38) ---
            List(beaconManager.beacons) { beacon in
                HStack {
                    Text(beacon.name)
                        .bold()
                    Spacer()
                    if beacon.smoothedRssi != 0 {
                        VStack(alignment: .trailing) {
                            Text(String(format: "%.1f m", beacon.distance))
                                .foregroundColor(.blue)
                                .bold()
                            Text("RSSI: \(Int(beacon.smoothedRssi))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("Nicht in Reichweite")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    // Umrechnung Meter -> Pixel (X)
    func calculateX(_ meters: Double) -> CGFloat {
        return CGFloat(meters * pixelsPerMeter)
    }
    
    // Umrechnung Meter -> Pixel (Y)
    // Story #39: "0,0 ist linke untere Ecke".
    // iOS: 0,0 ist OBEN links. Wir müssen also umrechnen.
    func calculateY(_ meters: Double) -> CGFloat {
        let mapHeight = 400.0
        return CGFloat(mapHeight - (meters * pixelsPerMeter))
    }
}

// Kleines View für den Beacon Punkt auf der Karte
struct BeaconView: View {
    let beacon: IndooroBeacon
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 20))
                .foregroundColor(isActive ? .blue : .gray)
                .background(
                    Circle()
                        .fill(isActive ? Color.blue.opacity(0.2) : Color.clear)
                        .frame(width: 40, height: 40)
                )
            
            Text(beacon.name)
                .font(.caption2)
                .bold()
        }
    }
    
    var isActive: Bool {
        return beacon.distance > 0 && beacon.distance < 5.0 // Aktiv wenn in Reichweite
    }
}

// Hilfsview für Gitterlinien
struct GridLines: View {
    var body: some View {
        Path { path in
            for i in 0..<10 {
                let x = CGFloat(i) * 80 // Alle 1 Meter
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: 400))
            }
            for i in 0..<10 {
                let y = CGFloat(i) * 80
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: 350, y: y))
            }
        }
        .stroke(Color.gray.opacity(0.2))
    }
}

#Preview {
    ContentView()
}