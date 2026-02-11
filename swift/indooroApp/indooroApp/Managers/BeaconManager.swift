import Foundation
import CoreBluetooth
import Combine
import CoreGraphics

class BeaconManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    
    // --- DATEN ---
    @Published var beacons: [IndooroBeacon] = []
    @Published var shelves: [LayoutElement] = []
    @Published var gridWidth: Double = 15.0
    @Published var gridHeight: Double = 20.0
    
    // Position & Navigation
    @Published var userPosition: CGPoint? = nil
    @Published var navigationPath: [CGPoint] = []   // Der berechnete Weg (Blaue Linie)
    @Published var targetPosition: CGPoint? = nil   // Wo wollen wir hin? (Roter Pin)
    
    // Suche
    @Published var searchResults: [Product] = []
    @Published var isSearching: Bool = false
    
    // API URL (Für Simulator: localhost)
    private let apiBase = "http://localhost:8080/api"
    
    // Internes
    private var centralManager: CBCentralManager?
    private var rssiBuffer: [String: [Int]] = [:]
    private var kalmanFilters: [String: KalmanFilter] = [:]
    private var updateTimer: Timer?
    private let startTime = Date()
    
    // Konfiguration
    let pathLossExp = 4.0
    private let defaultTxPower = -59.0
    
    override init() {
        super.init()
        loadLayoutFromJSON()
        
        // Filter initialisieren
        for beacon in beacons {
            kalmanFilters[beacon.name] = KalmanFilter(processNoise: 0.05, measurementNoise: 2.0)
        }
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        startUpdateTimer()
    }
    
    // --- NAVIGATION LOGIK (NEU) ---
    
    // 1. Ziel setzen basierend auf Produkt
    func setTargetProduct(_ product: Product?) {
        guard let product = product else {
            // Ziel löschen
            DispatchQueue.main.async {
                self.targetPosition = nil
                self.navigationPath = []
            }
            return
        }
        
        // LayoutCode parsen (z.B. "310/1/1/1" -> Kategorie "310")
        let shelfCategory = product.layoutCode.components(separatedBy: "/").first ?? ""
        
        // Passendes Regal finden
        // HINWEIS: Da LayoutElement evtl. keine 'category' Property hat, nutzen wir Labels als Fallback
        if let shelf = shelves.first(where: { element in
            // Mapping von ID zu Label (basierend auf deiner layout.json)
            if shelfCategory == "310" && element.label == "Obst & Gemüse" { return true }
            if shelfCategory == "420" && element.label == "Konserven & Saucen" { return true }
            if shelfCategory == "430" && element.label == "Teigwaren & Nudeln" { return true }
            if shelfCategory == "440" && element.label == "Müsli & Frühstück" { return true }
            if shelfCategory == "450" && element.label == "Öle & Essig" { return true }
            if shelfCategory == "470" && element.label == "Snacks & Süßwaren" { return true }
            if shelfCategory == "510" && (element.label?.contains("Getränke") ?? false) { return true }
            if shelfCategory == "520" && element.label == "Molkereiprodukte" { return true }
            if shelfCategory == "525" && element.label?.contains("Käse") == true { return true }
            if shelfCategory == "530" && element.label == "Tiefkühlprodukte" { return true }
            if shelfCategory == "610" && element.label == "Haushalt & Reinigung" { return true }
            if shelfCategory == "640" && element.label?.contains("Körperpflege") == true { return true }
            
            return false
        }) {
            // Ziel ist die Mitte des Regals
            let tx = shelf.x + (shelf.width ?? 1) / 2
            let ty = shelf.y + (shelf.height ?? 1) / 2
            
            DispatchQueue.main.async {
                self.targetPosition = CGPoint(x: tx, y: ty)
                self.updateNavigationPath() // Pfad sofort berechnen
            }
        } else {
            print("⚠️ Kein Regal gefunden für Kategorie \(shelfCategory)")
        }
    }
    
    // 2. Pfad neu berechnen
    private func updateNavigationPath() {
            // Prüfen ob Start und Ziel da sind
            guard let start = userPosition else {
                print("⚠️ Pfad-Update abgebrochen: Keine User-Position (Bitte auf Karte tippen!)")
                return
            }
            guard let end = targetPosition else {
                print("⚠️ Pfad-Update abgebrochen: Kein Ziel")
                return
            }
            
            print("🔄 Berechne Weg von \(start) nach \(end)...")
            
            DispatchQueue.global(qos: .userInitiated).async {
                let path = Pathfinder.findPath(
                    start: start,
                    end: end,
                    gridWidth: Int(self.gridWidth),
                    gridHeight: Int(self.gridHeight),
                    obstacles: self.shelves
                )
                
                DispatchQueue.main.async {
                    self.navigationPath = path
                    print("🏁 Pfad aktualisiert: \(path.count) Schritte")
                }
            }
        }
    
    // --- SUCHE ---
    
    func searchProducts(query: String) {
        guard !query.isEmpty else {
            self.searchResults = []
            return
        }
        
        self.isSearching = true
        let urlString = "\(apiBase)/products/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&size=50"
        
        guard let url = URL(string: urlString) else { return }
        print("🔎 Suche nach: \(query)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isSearching = false
                
                if let error = error {
                    print("❌ Fehler bei Suche: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    let products = try JSONDecoder().decode([Product].self, from: data)
                    self?.searchResults = products
                    print("✅ \(products.count) Produkte gefunden")
                } catch {
                    print("❌ JSON Fehler: \(error)")
                }
            }
        }.resume()
    }
    
    func clearSearch() {
        self.searchResults = []
    }
    
    // --- POSITIONIERUNG & BLE ---
    
    func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.processBufferAndCalculate()
        }
    }
    
    func processBufferAndCalculate() {
        if Date().timeIntervalSince(startTime) < 2.0 { return }
        
        // 1. RSSI Werte glätten
        for (name, values) in rssiBuffer {
            guard !values.isEmpty else { continue }
            
            let sortedValues = values.sorted()
            let filteredValues: [Int]
            if sortedValues.count >= 3 {
                filteredValues = Array(sortedValues.dropFirst().dropLast())
            } else {
                filteredValues = sortedValues
            }
            
            let averageRssi = Double(filteredValues.reduce(0, +)) / Double(filteredValues.count)
            let rawDistance = calculateDistance(rssi: averageRssi, txPower: defaultTxPower)
            let smoothedDistance = kalmanFilters[name]?.filter(rawDistance) ?? rawDistance
            
            updateBeaconUI(name: name, rssi: Int(averageRssi), distance: smoothedDistance)
        }
        rssiBuffer.removeAll()
        
        // 2. Position berechnen
        calculateLocation()
    }
    
    private func calculateLocation() {
        let activeBeacons = beacons.filter { $0.distance > 0.1 && $0.distance < 20.0 }
        guard activeBeacons.count >= 3 else { return }
        
        let top3 = activeBeacons.sorted { $0.distance < $1.distance }.prefix(3)
        var totalWeight: Double = 0
        var sumX: Double = 0
        var sumY: Double = 0
        
        for beacon in top3 {
            let weight = 1.0 / pow(beacon.distance, 2)
            sumX += beacon.positionX * weight
            sumY += beacon.positionY * weight
            totalWeight += weight
        }
        
        if totalWeight > 0 {
            let userX = sumX / totalWeight
            let userY = sumY / totalWeight
            
            DispatchQueue.main.async {
                self.userPosition = CGPoint(x: userX, y: userY)
                
                // WICHTIG: Wenn wir ein Ziel haben, Pfad aktualisieren!
                if self.targetPosition != nil {
                    self.updateNavigationPath()
                }
            }
        }
    }
    
    // --- HELPER ---
    
    private func loadLayoutFromJSON() {
        guard let url = Bundle.main.url(forResource: "layout", withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            let layout = try JSONDecoder().decode(LayoutData.self, from: data)
            self.gridWidth = layout.gridSize.width
            self.gridHeight = layout.gridSize.height
            self.shelves = layout.elements.filter { $0.type != "beacon" }
            self.beacons = layout.elements
                .filter { $0.type == "beacon" }
                .compactMap { element in
                    guard let name = element.beaconId else { return nil }
                    return IndooroBeacon(id: String(element.id), name: name, positionX: element.x, positionY: element.y)
                }
        } catch { print("❌ JSON Fehler beim Layout: \(error)") }
    }
    
    private func updateBeaconUI(name: String, rssi: Int, distance: Double) {
        if let index = beacons.firstIndex(where: { $0.name == name }) {
            var b = beacons[index]
            b.rssi = rssi
            b.distance = distance
            beacons[index] = b
        }
    }
    
    private func calculateDistance(rssi: Double, txPower: Double) -> Double {
        let exponent = (txPower - rssi) / (10.0 * pathLossExp)
        return pow(10.0, exponent)
    }
    
    // --- DELEGATE ---
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name ?? "Unknown"
        if name.contains("Indooro") {
            let val = RSSI.intValue
            if val == 127 || val == 0 { return }
            if rssiBuffer[name] == nil { rssiBuffer[name] = [] }
            rssiBuffer[name]?.append(val)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
}
