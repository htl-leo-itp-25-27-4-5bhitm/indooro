import SwiftUI

struct MapView: View {
    @ObservedObject var beaconManager: BeaconManager
    let pixelsPerMeter: Double
    let targetProduct: Product?
    
    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            ZStack(alignment: .topLeading) {
                
                // A) Hintergrund
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .border(Color.black, width: 2)
                    .frame(
                        width: CGFloat(beaconManager.gridWidth * pixelsPerMeter),
                        height: CGFloat(beaconManager.gridHeight * pixelsPerMeter)
                    )
                
                // B) Gitterlinien
                GridLines(
                    step: pixelsPerMeter,
                    width: CGFloat(beaconManager.gridWidth * pixelsPerMeter),
                    height: CGFloat(beaconManager.gridHeight * pixelsPerMeter),
                    gridCountX: Int(beaconManager.gridWidth),
                    gridCountY: Int(beaconManager.gridHeight)
                )
                
                // C) Regale
                ForEach(beaconManager.shelves) { element in
                    ShelfView(element: element, pixelsPerMeter: pixelsPerMeter)
                }
                
                // D) ZIEL-MARKER (Roter Pin auf dem richtigen Regal)
                if let target = targetProduct {
                    // Logik: Finde das Regal, dessen Kategorie zum Produkt passt
                    // Produkt Code z.B. "310/1/..." -> Kategorie "310"
                    let shelfCategory = target.layoutCode.components(separatedBy: "/").first ?? ""
                    
                    if let targetShelf = beaconManager.shelves.first(where: { $0.color != nil && ($0.label?.contains(shelfCategory) ?? false) || ($0.type == "shelf" && target.layoutCode.starts(with: "310")) }) ?? beaconManager.shelves.first(where: {
                        // Fallback: Wir suchen ein Regal, das grob zur ID passt (vereinfacht)
                        // In einer echten App würde man 'category' im JSON sauber mappen.
                        // Hier ein Hack für die Demo: Wenn Code 310 ist, nimm Obstregal
                        if target.layoutCode.starts(with: "310") && $0.label == "Obst & Gemüse" { return true }
                        if target.layoutCode.starts(with: "470") && $0.label == "Snacks & Süßwaren" { return true }
                        return false
                    }) {
                        TargetMapMarker()
                            .position(
                                x: CGFloat(targetShelf.x * pixelsPerMeter + ((targetShelf.width ?? 1) * pixelsPerMeter / 2)),
                                y: CGFloat(targetShelf.y * pixelsPerMeter + ((targetShelf.height ?? 1) * pixelsPerMeter / 2))
                            )
                            .zIndex(100) // Ganz oben
                    }
                }
                
                // E) Achsenbeschriftung
                MapAxes(
                    pixelsPerMeter: pixelsPerMeter,
                    gridWidth: Int(beaconManager.gridWidth),
                    gridHeight: Int(beaconManager.gridHeight)
                )
                
                // F) Beacons
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
                
                // G) User Position (Blauer Punkt)
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
            .padding()
        }
    }
}
