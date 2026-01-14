import SwiftUI

struct ContentView: View {
    @StateObject var beaconManager = BeaconManager()
    
    // Maßstab: 1 Meter = 80 Pixel auf dem Handy
    let pixelsPerMeter: Double = 80.0
    
    var body: some View {
        VStack {
            Text("Indooro Map")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            
            // --- DIE KARTE (U8) ---
            ZStack(alignment: .bottomLeading) {
                
                // 1. Raum-Hintergrund
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .border(Color.black, width: 2)
                
                // 2. Gitterlinien
                GridLines(step: pixelsPerMeter)
                
                // 3. Achsen-Beschriftung (Maßstab)
                MapAxes(pixelsPerMeter: pixelsPerMeter, width: 350, height: 400)
                
                // 4. Beacons zeichnen
                ForEach(beaconManager.beacons) { beacon in
                    BeaconMapItem(
                        beacon: beacon,
                        pixelsPerMeter: pixelsPerMeter
                    )
                    .position(
                        x: CGFloat(beacon.positionX * pixelsPerMeter),
                        y: CGFloat(400 - (beacon.positionY * pixelsPerMeter)) // Y invertiert (0 ist unten)
                    )
                }
            }
            .frame(width: 350, height: 400)
            .background(Color.white)
            // .clipped() entfernt, damit Achsen sichtbar sind
            .padding()
            
            // --- LISTE ---
            List(beaconManager.beacons) { beacon in
                HStack {
                    // Farbiger Status-Punkt
                    Circle()
                        .fill(colorForDistance(beacon.distance))
                        .frame(width: 10, height: 10)
                    
                    Text(beacon.name).bold()
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
                        Text("Suche...").foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // Hilfsfunktion für Farben
    func colorForDistance(_ dist: Double) -> Color {
        if dist <= 0 { return .gray }
        if dist < 1.5 { return .green }
        if dist < 4.0 { return .orange }
        return .red
    }
}

// MARK: - Beacon Map Icon
struct BeaconMapItem: View {
    let beacon: IndooroBeacon
    let pixelsPerMeter: Double
    
    // Farb-Logik
    var statusColor: Color {
        if beacon.distance <= 0 { return .gray.opacity(0.3) } // Inaktiv
        
        if beacon.distance < 1.5 { return .green }      // Nah
        if beacon.distance < 4.0 { return .orange }     // Mittel
        return .red                                     // Fern
    }
    
    var body: some View {
        ZStack {
            // Radius-Ring (Der "Radar"-Kreis)
            // Wird nur gezeichnet, wenn Beacon aktiv ist
            if beacon.distance > 0 {
                Circle()
                    .stroke(statusColor.opacity(0.4), lineWidth: 2) // Dünner Ring
                    .background(Circle().fill(statusColor.opacity(0.1))) // Leichte Füllung
                    .frame(
                        width: CGFloat(beacon.distance * pixelsPerMeter * 2), // Durchmesser = Radius * 2
                        height: CGFloat(beacon.distance * pixelsPerMeter * 2)
                    )
                    .allowsHitTesting(false) // Klicks gehen durch
            }
            
            // Das eigentliche Icon
            VStack(spacing: 0) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 20))
                    .foregroundColor(statusColor)
                    .background(
                        Circle()
                            .fill(Color.white) // Weißer Hintergrund
                            .frame(width: 30, height: 30)
                            .shadow(radius: 2)
                    )
                
                Text(beacon.name)
                    .font(.caption2)
                    .bold()
                    .padding(2)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
                    .offset(y: 4)
            }
        }
    }
}

// MARK: - Achsenbeschriftung
struct MapAxes: View {
    let pixelsPerMeter: Double
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            // X-Achse (Unten)
            ForEach(0..<6) { meter in
                let xPos = CGFloat(Double(meter) * pixelsPerMeter)
                if xPos <= width {
                    Text("\(meter)m")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .position(x: xPos, y: height + 15) // Unter den Rand
                }
            }
            
            // Y-Achse (Links)
            ForEach(0..<6) { meter in
                let yPos = height - CGFloat(Double(meter) * pixelsPerMeter)
                if yPos >= 0 {
                    Text("\(meter)m")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .position(x: -15, y: yPos) // Links vom Rand
                }
            }
        }
    }
}

// Gitterlinien
struct GridLines: View {
    let step: Double
    var body: some View {
        Path { path in
            // Vertikal
            for i in 0..<10 {
                let pos = CGFloat(Double(i) * step)
                path.move(to: CGPoint(x: pos, y: 0))
                path.addLine(to: CGPoint(x: pos, y: 400))
                // Horizontal
                path.move(to: CGPoint(x: 0, y: pos))
                path.addLine(to: CGPoint(x: 350, y: pos))
            }
        }
        .stroke(Color.gray.opacity(0.2))
    }
}

#Preview {
    ContentView()
}
