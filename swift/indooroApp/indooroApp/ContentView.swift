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
            
            // === KALIBRIERUNGS-BEREICH ===
            if beaconManager.isCalibrating {
                VStack(spacing: 12) {
                    Text("🔧 KALIBRIERUNG LÄUFT")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("1. Stelle dein iPhone GENAU 1 Meter\n   von einem Beacon entfernt")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    
                    Text("2. Warte 10 Sekunden")
                        .font(.caption)
                    
                    Text("3. Drücke 'Fertig' und notiere\n   die Werte aus der Konsole")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    
                    Button("✅ Kalibrierung beenden") {
                        beaconManager.stopCalibration()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                Button("🔧 Kalibrierung starten") {
                    beaconManager.startCalibration()
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 8)
            }
            
            // --- DIE KARTE ---
            ZStack(alignment: .bottomLeading) {
                // Raum-Hintergrund
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .border(Color.black, width: 2)
                
                // Gitterlinien
                GridLines(step: pixelsPerMeter)
                
                // Beacons zeichnen
                ForEach(beaconManager.beacons) { beacon in
                    BeaconMapItem(beacon: beacon, isCalibrating: beaconManager.isCalibrating)
                        .position(
                            x: CGFloat(beacon.positionX * pixelsPerMeter),
                            y: CGFloat(400 - (beacon.positionY * pixelsPerMeter)) // Y invertieren
                        )
                }
            }
            .frame(width: 350, height: 400)
            .background(Color.white)
            .clipped()
            
            // --- LISTE ---
            List(beaconManager.beacons) { beacon in
                HStack {
                    Text(beacon.name).bold()
                    Spacer()
                    if beaconManager.isCalibrating {
                        VStack(alignment: .trailing) {
                            Text("📏 1.00 m")
                                .foregroundColor(.orange)
                                .bold()
                            Text("\(beacon.rssi) dBm")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else if beacon.distance > 0 {
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
}

// Das Icon auf der Karte
struct BeaconMapItem: View {
    let beacon: IndooroBeacon
    let isCalibrating: Bool
    
    // Aktiv, wenn Signal da ist und logisch (< 10m)
    var isActive: Bool {
        return beacon.distance > 0 && beacon.distance < 10.0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: isCalibrating ? "ruler" : "antenna.radiowaves.left.and.right")
                .font(.system(size: 20))
                .foregroundColor(isCalibrating ? .orange : (isActive ? .blue : .gray.opacity(0.3)))
                .background(
                    Circle()
                        .fill(isCalibrating ? Color.orange.opacity(0.2) : (isActive ? Color.blue.opacity(0.2) : Color.clear))
                        .frame(width: 40, height: 40)
                )
            Text(beacon.name)
                .font(.caption2)
                .bold()
                .offset(y: 4)
        }
    }
}

// Gitterlinien-Zeichner
struct GridLines: View {
    let step: Double
    var body: some View {
        Path { path in
            // Vertikal
            for i in 0..<10 {
                let pos = CGFloat(Double(i) * step)
                path.move(to: CGPoint(x: pos, y: 0))
                path.addLine(to: CGPoint(x: pos, y: 400))
            }
            // Horizontal
            for i in 0..<10 {
                let pos = CGFloat(Double(i) * step)
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
