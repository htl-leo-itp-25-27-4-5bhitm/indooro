import SwiftUI

struct MapView: View {
    @ObservedObject var beaconManager: BeaconManager
    let pixelsPerMeter: Double
    let targetProduct: Product?
    
    var body: some View {
        // Nur vertikal scrollen, Breite ist eingepasst
        ScrollView([.vertical], showsIndicators: true) {
            ZStack(alignment: .topLeading) {
                
                // 1. Hintergrund
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
                
                // 3. PFAD LINIE (ULTRA SMOOTH - KANTEN GLÄTTEN)
                if !beaconManager.navigationPath.isEmpty {
                    Path { path in
                        // Umrechnen der Grid-Punkte in Pixel-Koordinaten
                        let points = beaconManager.navigationPath.map {
                            CGPoint(x: $0.x * pixelsPerMeter, y: $0.y * pixelsPerMeter)
                        }
                        
                        if points.count > 1 {
                            // Startpunkt
                            path.move(to: points[0])
                            
                            if points.count == 2 {
                                // Wenn nur 2 Punkte, ist es eine gerade Linie
                                path.addLine(to: points[1])
                            } else {
                                // Der Glättungs-Algorithmus:
                                // Wir zeichnen Linien/Kurven zwischen den MITTELPUNKTEN der Segmente.
                                
                                for i in 1..<points.count {
                                    let p0 = points[i-1] // Vorheriger Punkt (Ecke)
                                    let p1 = points[i]   // Aktueller Punkt (Ecke)
                                    
                                    // Mittelpunkt zwischen p0 und p1 berechnen
                                    let midPoint = CGPoint(
                                        x: (p0.x + p1.x) / 2,
                                        y: (p0.y + p1.y) / 2
                                    )
                                    
                                    if i == 1 {
                                        // Vom allerersten Startpunkt eine gerade Linie zum ersten Mittelpunkt
                                        path.addLine(to: midPoint)
                                    } else {
                                        // Der magische Teil: Zeichne eine Kurve vom VORHERIGEN Mittelpunkt
                                        // zum JETZIGEN Mittelpunkt.
                                        // Der "scharfe" Eckpunkt (p0) wird als Kontrollpunkt genutzt,
                                        // der die Linie wie ein Magnet zu sich zieht und so abrundet.
                                        path.addQuadCurve(to: midPoint, control: p0)
                                    }
                                }
                                
                                // Am Ende eine gerade Linie vom letzten Mittelpunkt zum echten Endziel
                                if let last = points.last {
                                    path.addLine(to: last)
                                }
                            }
                        }
                    }
                    // Linie etwas dicker (lineWidth: 5) und blau
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    // Leichter Schatten, damit es plastischer wirkt
                    .shadow(color: Color.blue.opacity(0.5), radius: 5, x: 0, y: 0)
                }
                
                // 4. Regale
                ForEach(beaconManager.shelves) { element in
                    ShelfView(element: element, pixelsPerMeter: pixelsPerMeter)
                }
                
                // 5. Ziel-Marker (Roter Pin)
                if let targetPos = beaconManager.targetPosition {
                    TargetMapMarker()
                        .position(
                            x: CGFloat(targetPos.x * pixelsPerMeter),
                            y: CGFloat(targetPos.y * pixelsPerMeter)
                        )
                        .zIndex(100)
                }
                
                // 6. Achsen (Habe die Zahlen etwas weiter nach außen geschoben)
                MapAxes(
                    pixelsPerMeter: pixelsPerMeter,
                    gridWidth: Int(beaconManager.gridWidth),
                    gridHeight: Int(beaconManager.gridHeight)
                )
                
                // 7. Beacons
                ForEach(beaconManager.beacons) { beacon in
                    BeaconMapItem(beacon: beacon, pixelsPerMeter: pixelsPerMeter)
                        .position(
                            x: CGFloat(beacon.positionX * pixelsPerMeter),
                            y: CGFloat(beacon.positionY * pixelsPerMeter)
                        )
                }
                
                // 8. User Position (Blauer Punkt)
                if let pos = beaconManager.userPosition {
                    UserLocationMarker()
                        .position(
                            x: CGFloat(pos.x * pixelsPerMeter),
                            y: CGFloat(pos.y * pixelsPerMeter)
                        )
                        .animation(.easeInOut(duration: 0.5), value: pos)
                }
                
                // --- DEBUG FEATURE: TIPPEN ZUM BEWEGEN ---
                Color.white.opacity(0.001)
                    .frame(
                        width: CGFloat(beaconManager.gridWidth * pixelsPerMeter),
                        height: CGFloat(beaconManager.gridHeight * pixelsPerMeter)
                    )
                    .onTapGesture { location in
                        let xMeter = Double(location.x) / pixelsPerMeter
                        let yMeter = Double(location.y) / pixelsPerMeter
                        beaconManager.userPosition = CGPoint(x: xMeter, y: yMeter)
                        if beaconManager.targetPosition != nil {
                            beaconManager.setTargetProduct(targetProduct)
                        }
                    }
            }
            .frame(
                width: CGFloat(beaconManager.gridWidth * pixelsPerMeter),
                height: CGFloat(beaconManager.gridHeight * pixelsPerMeter)
            )
            // Padding etwas erhöht, damit die Achsenbeschriftung Platz hat
            .padding(EdgeInsets(top: 30, leading: 30, bottom: 20, trailing: 20))
        }
    }
}
