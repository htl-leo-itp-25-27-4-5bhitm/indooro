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
    @Published var navigationPath: [CGPoint] = []   // Pfad (Blaue Linie)
    @Published var targetPosition: CGPoint? = nil   // Ziel (Roter Pin)
    
    // Suche
    @Published var searchResults: [Product] = []
    @Published var isSearching: Bool = false
    
    // Produktliste
    @Published var allProducts: [Product] = []
    @Published var isLoadingProducts: Bool = false
    @Published var productLoadingError: String? = nil
    
    // API URL der LeoCloud-Instanz
    private let apiBase = "https://it220209.cloud.htl-leonding.ac.at/api"

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
        loadLayoutFromBundle()
        loadLayoutFromServer()
        
        // Filter initialisieren
        for beacon in beacons {
            kalmanFilters[beacon.name] = KalmanFilter(processNoise: 0.05, measurementNoise: 2.0)
        }
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        startUpdateTimer()
    }
    
    // --- NAVIGATION LOGIK (ANGEPASST AN NEUES JSON) ---
    
    func setTargetProduct(_ product: Product?) {
        guard let product = product else {
            // Ziel löschen
            DispatchQueue.main.async {
                self.targetPosition = nil
                self.navigationPath = []
            }
            return
        }
        
        // 1. Produkt-Code zerlegen (z.B. "310/2/1/1")
        // Format ist meistens: Kategorie/Meter/Ebene/Position
        let parts = product.layoutCode.components(separatedBy: "/")
        
        guard !parts.isEmpty else {
            print("⚠️ Ungültiger LayoutCode: \(product.layoutCode)")
            return
        }
        
        let prodCategory = parts[0] // z.B. "310"
        
        // Versuchen, den Meter aus dem Produkt-Code zu lesen (Index 1)
        var prodMeter: Int? = nil
        if parts.count > 1 {
            prodMeter = Int(parts[1])
        }
        
        print("🎯 Suche Regal für Kat: \(prodCategory), Meter: \(prodMeter ?? -1)")

        // 2. Passendes Regal im Layout suchen
        if let shelf = shelves.first(where: { element in
            // Hat das Regal überhaupt eine Kategorie? (Kassen etc. haben oft keine)
            guard let elCategory = element.category else { return false }
            
            // A) Kategorie-Check
            // Wir prüfen, ob die Regal-Kategorie mit der Produkt-Kategorie beginnt.
            // (JSON kann "310/2" sein, Produkt "310". Beides fängt mit "310" an)
            if !elCategory.starts(with: prodCategory) {
                return false
            }
            
            // B) Meter-Check (Das ist neu!)
            if let elMeter = element.meter {
                // Fall 1: Regal hat einen Meter (z.B. 2).
                // Dann MUSS das Produkt auch diesen Meter suchen.
                if let pMeter = prodMeter {
                    return elMeter == pMeter
                } else {
                    // Produkt hat keinen Meter im Code, Regal aber schon -> Passt nicht exakt.
                    return false
                }
            } else {
                // Fall 2: Regal hat KEINEN Meter (nil).
                // Das bedeutet, das Regal gilt für die ganze Kategorie (oder Meter ist egal).
                // Da die Kategorie (A) schon passt, ist das ein Treffer.
                return true
            }
        }) {
            // 3. Ziel setzen (Mitte des gefundenen Regals)
            let tx = shelf.x + (shelf.width ?? 1) / 2
            let ty = shelf.y + (shelf.height ?? 1) / 2
            
            DispatchQueue.main.async {
                self.targetPosition = CGPoint(x: tx, y: ty)
                self.updateNavigationPath() // Pfad sofort berechnen
                print("✅ Ziel gefunden bei x:\(tx) y:\(ty) (Regal: \(shelf.label ?? "Unbekannt"))")
            }
        } else {
            print("⚠️ Kein Regal gefunden für \(product.name) (Code: \(product.layoutCode))")
        }
    }
    
    // Pfad neu berechnen
    private func updateNavigationPath() {
        guard let start = userPosition, let end = targetPosition else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Ruft den Pathfinder auf (den Code hast du ja schon in Pathfinder.swift)
            let path = Pathfinder.findPath(
                start: start,
                end: end,
                gridWidth: Int(self.gridWidth),
                gridHeight: Int(self.gridHeight),
                obstacles: self.shelves
            )
            
            DispatchQueue.main.async {
                self.navigationPath = path
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
                    let products = try self?.decodeProducts(from: data) ?? []
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
    
    func loadAllProducts(forceReload: Bool = false) {
        guard !isLoadingProducts else { return }
        if !forceReload, !allProducts.isEmpty { return }
        
        isLoadingProducts = true
        productLoadingError = nil
        
        let encodedQuery = "".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let endpoints = [
            "\(apiBase)/products?size=400",
            "\(apiBase)/products/search?q=\(encodedQuery)&size=400",
            "\(apiBase)/products/search?q=a&size=400"
        ]
        
        fetchProducts(from: endpoints, attempt: 0)
    }
    
    // --- PRODUKT API ---
    
    private func fetchProducts(from endpoints: [String], attempt: Int) {
        guard attempt < endpoints.count, let url = URL(string: endpoints[attempt]) else {
            DispatchQueue.main.async {
                self.isLoadingProducts = false
                self.productLoadingError = "Produkte konnten nicht geladen werden."
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }
            
            if let error {
                print("❌ Produktliste Fehler: \(error.localizedDescription)")
                self.fetchProducts(from: endpoints, attempt: attempt + 1)
                return
            }
            
            guard let data else {
                self.fetchProducts(from: endpoints, attempt: attempt + 1)
                return
            }
            
            do {
                let decoded = try self.decodeProducts(from: data)
                if decoded.isEmpty {
                    self.fetchProducts(from: endpoints, attempt: attempt + 1)
                    return
                }
                
                let sorted = Array(Set(decoded)).sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                
                DispatchQueue.main.async {
                    self.allProducts = sorted
                    self.isLoadingProducts = false
                    self.productLoadingError = nil
                }
            } catch {
                print("❌ Produktliste JSON Fehler: \(error)")
                self.fetchProducts(from: endpoints, attempt: attempt + 1)
            }
        }.resume()
    }
    
    private func decodeProducts(from data: Data) throws -> [Product] {
        if let direct = try? JSONDecoder().decode([Product].self, from: data) {
            return direct
        }
        
        let page = try JSONDecoder().decode(PagedProductResponse.self, from: data)
        return page.content
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
                
                // Wenn wir ein Ziel haben, Pfad aktualisieren
                if self.targetPosition != nil {
                    self.updateNavigationPath()
                }
            }
        }
    }
    
    // --- HELPER ---
    
    private func loadLayoutFromServer() {
        guard let url = URL(string: "\(apiBase)/layout/current") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }

            if let error {
                print("❌ Server-Layout konnte nicht geladen werden: \(error.localizedDescription)")
                return
            }

            guard let data else { return }

            do {
                let layout = try JSONDecoder().decode(LayoutData.self, from: data)
                DispatchQueue.main.async {
                    self.applyLayout(layout)
                }
            } catch {
                print("❌ JSON Fehler beim Server-Layout: \(error)")
            }
        }.resume()
    }

    private func loadLayoutFromBundle() {
        guard let url = Bundle.main.url(forResource: "layout", withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            let layout = try JSONDecoder().decode(LayoutData.self, from: data)
            applyLayout(layout)
        } catch { print("❌ JSON Fehler beim Layout: \(error)") }
    }

    private func applyLayout(_ layout: LayoutData) {
        self.gridWidth = layout.gridSize.width
        self.gridHeight = layout.gridSize.height
        self.shelves = layout.elements.filter { $0.type != "beacon" }
        self.beacons = layout.elements
            .filter { $0.type == "beacon" }
            .compactMap { element in
                guard let name = element.beaconId else { return nil }
                return IndooroBeacon(id: String(element.id), name: name, positionX: element.x, positionY: element.y)
            }
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

private struct PagedProductResponse: Decodable {
    let content: [Product]
}
