import SwiftUI

struct MapView: View {
    @ObservedObject var beaconManager: BeaconManager
    let pixelsPerMeter: Double
    let targetProduct: Product?
    
    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
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
                
                // 3. PFAD LINIE (Zuerst zeichnen, damit sie unter den Regalen liegt)
                if !beaconManager.navigationPath.isEmpty {
                    Path { path in
                        if let first = beaconManager.navigationPath.first {
                            path.move(to: CGPoint(
                                x: first.x * pixelsPerMeter,
                                y: first.y * pixelsPerMeter
                            ))
                        }
                        for point in beaconManager.navigationPath.dropFirst() {
                            path.addLine(to: CGPoint(
                                x: point.x * pixelsPerMeter,
                                y: point.y * pixelsPerMeter
                            ))
                        }
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
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
                
                // 6. Achsen
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
                // Ein unsichtbarer Layer über allem, der Klicks abfängt
                Color.white.opacity(0.001) // Fast transparent, aber klickbar
                    .frame(
                        width: CGFloat(beaconManager.gridWidth * pixelsPerMeter),
                        height: CGFloat(beaconManager.gridHeight * pixelsPerMeter)
                    )
                    .onTapGesture { location in
                        // location ist in Pixeln -> Umrechnen in Meter
                        let xMeter = Double(location.x) / pixelsPerMeter
                        let yMeter = Double(location.y) / pixelsPerMeter
                        
                        print("📍 Debug: Setze Position auf x:\(xMeter) y:\(yMeter)")
                        
                        // User Position manuell setzen
                        beaconManager.userPosition = CGPoint(x: xMeter, y: yMeter)
                        
                        // Wenn ein Ziel aktiv ist, Route sofort neu berechnen!
                        // Dazu rufen wir den Pathfinder indirekt über den Manager auf
                        if beaconManager.targetPosition != nil {
                            // Kleiner Hack: Wir simulieren, dass ein Ziel gesetzt wurde,
                            // damit der Manager den Pfad updated.
                            // Sauberer wäre eine public updatePath() methode im Manager,
                            // aber das reicht für den Test.
                            beaconManager.setTargetProduct(targetProduct)
                        }
                    }
            }
            .frame(
                width: CGFloat(beaconManager.gridWidth * pixelsPerMeter),
                height: CGFloat(beaconManager.gridHeight * pixelsPerMeter)
            )
            .padding()
        }
    }
}
