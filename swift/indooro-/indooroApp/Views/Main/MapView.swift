import SwiftUI

struct MapView: View {
    @ObservedObject var beaconManager: BeaconManager
    let pixelsPerMeter: Double
    let targetProduct: Product?
    let shoppingStops: [ShoppingStop]
    let activeShoppingStopID: String?
    let showsShoppingSession: Bool
    let topInset: CGFloat
    let bottomInset: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let mapWidth = CGFloat(beaconManager.gridWidth * pixelsPerMeter)
            let mapHeight = CGFloat(beaconManager.gridHeight * pixelsPerMeter)
            let displayUserPosition = beaconManager.userPosition ?? beaconManager.rawUserPosition
            let visibleHeight = max(0, geometry.size.height - topInset - bottomInset)

            VStack(spacing: 0) {
                Color.clear
                    .frame(height: topInset)

                ScrollView([.vertical], showsIndicators: true) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        ZStack(alignment: .topLeading) {
                            
                            // 1. Hintergrund
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .border(Color.black, width: 2)
                                .frame(width: mapWidth, height: mapHeight)
                            
                            // 2. Gitterlinien
                            GridLines(
                                step: pixelsPerMeter,
                                width: mapWidth,
                                height: mapHeight,
                                gridCountX: Int(beaconManager.gridWidth),
                                gridCountY: Int(beaconManager.gridHeight)
                            )
                            
                            // 3. PFAD LINIE (ULTRA SMOOTH - KANTEN GLÄTTEN)
                            if !beaconManager.navigationRoute.cgPoints.isEmpty {
                                Path { path in
                                    let points = beaconManager.navigationRoute.cgPoints.map {
                                        CGPoint(x: $0.x * pixelsPerMeter, y: $0.y * pixelsPerMeter)
                                    }
                                    
                                    if points.count > 1 {
                                        path.move(to: points[0])
                                        
                                        if points.count == 2 {
                                            path.addLine(to: points[1])
                                        } else {
                                            for i in 1..<points.count {
                                                let p0 = points[i - 1]
                                                let p1 = points[i]
                                                let midPoint = CGPoint(
                                                    x: (p0.x + p1.x) / 2,
                                                    y: (p0.y + p1.y) / 2
                                                )
                                                
                                                if i == 1 {
                                                    path.addLine(to: midPoint)
                                                } else {
                                                    path.addQuadCurve(to: midPoint, control: p0)
                                                }
                                            }
                                            
                                            if let last = points.last {
                                                path.addLine(to: last)
                                            }
                                        }
                                    }
                                }
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                                .shadow(color: Color.blue.opacity(0.5), radius: 5, x: 0, y: 0)
                            }
                            
                            // 4. Regale
                            ForEach(beaconManager.shelves) { element in
                                ShelfView(element: element, pixelsPerMeter: pixelsPerMeter)
                            }
                            
                            // 5. Ziel-Marker (Roter Pin)
                            if !showsShoppingSession, let targetPos = beaconManager.targetPosition {
                                TargetMapMarker()
                                    .position(
                                        x: CGFloat(targetPos.x * pixelsPerMeter),
                                        y: CGFloat(targetPos.y * pixelsPerMeter)
                                    )
                                    .zIndex(100)
                            }

                            if !shoppingStops.isEmpty {
                                ForEach(Array(shoppingStops.enumerated()), id: \.element.id) { index, stop in
                                    ShoppingStopMarker(
                                        index: index + 1,
                                        isActive: stop.id == activeShoppingStopID
                                    )
                                    .position(
                                        x: CGFloat(stop.mapPoint.x * pixelsPerMeter),
                                        y: CGFloat(stop.mapPoint.y * pixelsPerMeter)
                                    )
                                    .zIndex(stop.id == activeShoppingStopID ? 120 : 95)
                                }
                            }
                            
                            // 6. Achsen
                            MapAxes(
                                pixelsPerMeter: pixelsPerMeter,
                                gridWidth: Int(beaconManager.gridWidth),
                                gridHeight: Int(beaconManager.gridHeight)
                            )
                            
                            // 7. Beacons
                            if beaconManager.trackingMode == .beacon {
                                ForEach(beaconManager.beacons) { beacon in
                                    BeaconMapItem(beacon: beacon, pixelsPerMeter: pixelsPerMeter)
                                        .position(
                                            x: CGFloat(beacon.positionX * pixelsPerMeter),
                                            y: CGFloat(beacon.positionY * pixelsPerMeter)
                                        )
                                }
                            }
                            
                            // 8. User Position
                            if let pos = displayUserPosition {
                                UserLocationMarker(headingRadians: beaconManager.userHeadingRadians)
                                    .position(
                                        x: CGFloat(pos.x * pixelsPerMeter),
                                        y: CGFloat(pos.y * pixelsPerMeter)
                                    )
                                    .animation(.easeInOut(duration: 0.5), value: pos)
                                    .animation(.easeInOut(duration: 0.16), value: beaconManager.userHeadingRadians)
                            }
                            
                            // --- DEBUG FEATURE: TIPPEN ZUM BEWEGEN ---
                            Color.white.opacity(0.001)
                                .frame(width: mapWidth, height: mapHeight)
                                .contentShape(Rectangle())
                                .onTapGesture { location in
                                    let xMeter = Double(location.x) / pixelsPerMeter
                                    let yMeter = Double(location.y) / pixelsPerMeter
                                    let point = CGPoint(x: xMeter, y: yMeter)
                                    if beaconManager.tapSetsTarget {
                                        beaconManager.setManualTargetPosition(point)
                                    } else {
                                        beaconManager.setManualUserPosition(point)
                                    }
                                }
                        }
                        .frame(width: mapWidth, height: mapHeight)
                        .padding(EdgeInsets(top: 30, leading: 24, bottom: 20, trailing: 24))

                        Spacer(minLength: 0)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: max(visibleHeight, mapHeight + 50),
                        alignment: .center
                    )
                }

                Color.clear
                    .frame(height: bottomInset)
            }
        }
    }
}
