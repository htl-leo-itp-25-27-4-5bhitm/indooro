import SwiftUI

struct ContentView: View {
    @StateObject var beaconManager = BeaconManager()
    
    // --- SUCHE STATES ---
    @State private var searchText = ""
    @State private var targetProduct: Product? = nil // Das aktuell gesuchte Produkt
    
    // Maßstab: 25 Pixel pro Meter
    let pixelsPerMeter: Double = 25.0
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                
                // === HAUPT-LAYOUT (Karte & Header) ===
                VStack(spacing: 0) {
                    
                    // 1. KOPFZEILE
                    VStack(spacing: 5) {
                        Text("Indooro Map")
                            .font(.largeTitle)
                            .bold()
                        
                        // Status: User Position
                        if let pos = beaconManager.userPosition {
                            Text("📍 Position: \(String(format: "%.1f", pos.x))m / \(String(format: "%.1f", pos.y))m")
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else {
                            Text("📡 Suche Position... (Brauche 3 Signale)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // ANZEIGE: ZIEL-PRODUKT (Grüne Box)
                        if let target = targetProduct {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Ziel: \(target.name)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Regal-Code: \(target.layoutCode)")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation { targetProduct = nil } // Ziel löschen
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                }
                            }
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.top, 5)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 10)
                    .background(Color.white)
                    .zIndex(1) // Sicherstellen, dass Header über der Map liegt
                    
                    // 2. SCROLLBARE KARTE
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
                .blur(radius: beaconManager.searchResults.isEmpty ? 0 : 3) // Weichzeichnen wenn Suche aktiv
                
                // === SUCHE OVERLAY ===
                VStack(spacing: 0) {
                    // Suchleiste
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Produkt suchen...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: searchText) { newValue in
                                if newValue.count > 2 {
                                    beaconManager.searchProducts(query: newValue)
                                } else {
                                    beaconManager.clearSearch()
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                beaconManager.clearSearch()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Ergebnis Liste
                    if !beaconManager.searchResults.isEmpty {
                        List(beaconManager.searchResults, id: \.self) { product in // id: \.self fixt den Crash!
                            Button(action: {
                                // AKTION BEI KLICK
                                withAnimation {
                                    targetProduct = product // Ziel setzen
                                    searchText = ""         // Text leeren
                                    beaconManager.clearSearch() // Liste leeren
                                }
                                // Tastatur schließen
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }) {
                                VStack(alignment: .leading) {
                                    Text(product.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    HStack {
                                        Text(String(format: "%.2f €", product.price))
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                        Spacer()
                                        Text("Code: \(product.layoutCode)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .padding(.top, 5)
                        .listStyle(.plain)
                        .background(Color.clear)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // Hilfsfunktion für Farben
    func colorForDistance(_ dist: Double) -> Color {
        if dist <= 0 { return .gray }
        if dist < 2.0 { return .green }
        return .orange
    }
}

// ==========================================
// MARK: - SUBVIEWS (Alle Helper Views)
// ==========================================

// 1. REGAL VIEW
struct ShelfView: View {
    let element: LayoutElement
    let pixelsPerMeter: Double
    
    var body: some View {
        let width = CGFloat((element.width ?? 1) * pixelsPerMeter)
        let height = CGFloat((element.height ?? 1) * pixelsPerMeter)
        
        // Position berechnen (Mitte vs Oben-Links Anpassung)
        let xPos = CGFloat(element.x * pixelsPerMeter) + (width / 2)
        let yPos = CGFloat(element.y * pixelsPerMeter) + (height / 2)
        
        Rectangle()
            .fill(Color(hex: element.color ?? "#CCCCCC"))
            .overlay(
                Text(element.label ?? "")
                    .font(.system(size: 8))
                    .foregroundColor(.black.opacity(0.6))
                    .padding(2)
                    .lineLimit(1)
            )
            .frame(width: width, height: height)
            .position(x: xPos, y: yPos)
    }
}

// 2. BEACON VIEW
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
            // Radar-Kreis (nur wenn Signal da ist)
            if beacon.distance > 0 && beacon.distance < 10 {
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
                    .frame(
                        width: CGFloat(beacon.distance * pixelsPerMeter * 2),
                        height: CGFloat(beacon.distance * pixelsPerMeter * 2)
                    )
            }
            
            // Icon
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

// 3. USER MARKER (Blauer Punkt)
struct UserLocationMarker: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Pulsierender äußerer Kreis
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .scaleEffect(isPulsing ? 1.2 : 0.8)
                .opacity(isPulsing ? 0.0 : 0.5)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                        isPulsing = true
                    }
                }
            
            // Fester Kern
            Circle()
                .fill(Color.blue)
                .frame(width: 15, height: 15)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(radius: 2)
            
            Text("ICH")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.blue)
                .offset(y: -16)
        }
    }
}

// 4. ZIEL MARKER (Roter Pin für Produkte) - NEU
struct TargetMapMarker: View {
    @State private var bounce = false
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.red)
                .background(Circle().fill(.white))
                .shadow(radius: 3)
            
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundColor(.red)
                .offset(y: -5)
        }
        .offset(y: bounce ? -10 : 0)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                bounce = true
            }
        }
    }
}

// 5. GITTERLINIEN
struct GridLines: View {
    let step: Double
    let width: CGFloat
    let height: CGFloat
    let gridCountX: Int
    let gridCountY: Int
    
    var body: some View {
        Path { path in
            // Vertikale Linien
            for i in 0...gridCountX {
                let pos = CGFloat(Double(i) * step)
                path.move(to: CGPoint(x: pos, y: 0))
                path.addLine(to: CGPoint(x: pos, y: height))
            }
            // Horizontale Linien
            for i in 0...gridCountY {
                let pos = CGFloat(Double(i) * step)
                path.move(to: CGPoint(x: 0, y: pos))
                path.addLine(to: CGPoint(x: width, y: pos))
            }
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }
}

// 6. ACHSENBESCHRIFTUNG
struct MapAxes: View {
    let pixelsPerMeter: Double
    let gridWidth: Int
    let gridHeight: Int
    
    var body: some View {
        ZStack {
            // X-Achse
            ForEach(0...gridWidth, id: \.self) { meter in
                if meter % 2 == 0 { // Nur jeden 2. Meter anzeigen damit es nicht zu voll wird
                    let xPos = CGFloat(Double(meter) * pixelsPerMeter)
                    Text("\(meter)")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .position(x: xPos, y: -10)
                }
            }
            // Y-Achse
            ForEach(0...gridHeight, id: \.self) { meter in
                if meter % 2 == 0 {
                    let yPos = CGFloat(Double(meter) * pixelsPerMeter)
                    Text("\(meter)")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .position(x: -10, y: yPos)
                }
            }
        }
    }
}

// 7. FARB EXTENSION (Hex Support)
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

// Preview für Canvas
#Preview {
    ContentView()
}
