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
    
    // Position des Nutzers
    @Published var userPosition: CGPoint? = nil
    
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
    
    // --- SUCH FUNKTION ---
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
                    // Dekodieren der externen Product Klasse
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
    
    // --- LAYOUT LADEN ---
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
        } catch { print("❌ JSON Fehler: \(error)") }
    }
    
    // --- POSITIONIERUNG ---
    func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.processBufferAndCalculate()
        }
    }
    
    func processBufferAndCalculate() {
        if Date().timeIntervalSince(startTime) < 2.0 { return }
        
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
            }
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
    
    // --- BLUETOOTH DELEGATE ---
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
