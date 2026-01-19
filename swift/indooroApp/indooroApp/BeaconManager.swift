import Foundation
import CoreBluetooth
import Combine

class BeaconManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    
    @Published var beacons: [IndooroBeacon] = []
    @Published var shelves: [LayoutElement] = [] // NEU: Liste der Regale
    @Published var gridWidth: Double = 15.0
    @Published var gridHeight: Double = 20.0
    
    private var centralManager: CBCentralManager?
    private var rssiBuffer: [String: [Int]] = [:]
    private var kalmanFilters: [String: KalmanFilter] = [:]
    private var updateTimer: Timer?
    private let startTime = Date()
    
    // Konfiguration
    let pathLossExp = 2.0
    private let defaultTxPower = -59.0
    
    override init() {
        super.init()
        
        // 1. Laden des Layouts (Beacons + Regale)
        loadLayoutFromJSON()
        
        // 2. Filter initialisieren
        for beacon in beacons {
            kalmanFilters[beacon.name] = KalmanFilter(processNoise: 0.05, measurementNoise: 2.0)
        }
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        startUpdateTimer()
    }
    
    private func loadLayoutFromJSON() {
        guard let url = Bundle.main.url(forResource: "layout", withExtension: "json") else {
            print("⚠️ layout.json nicht gefunden!")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let layout = try JSONDecoder().decode(LayoutData.self, from: data)
            
            // Grid Größe übernehmen
            self.gridWidth = layout.gridSize.width
            self.gridHeight = layout.gridSize.height
            
            // 1. Regale filtern (Alles was kein Beacon ist)
            self.shelves = layout.elements.filter { $0.type != "beacon" }
            
            // 2. Beacons filtern und konvertieren
            self.beacons = layout.elements
                .filter { $0.type == "beacon" }
                .compactMap { element in
                    guard let name = element.beaconId else { return nil }
                    return IndooroBeacon(
                        id: String(element.id),
                        name: name,
                        positionX: element.x,
                        positionY: element.y
                    )
                }
            
            print("✅ Layout geladen: \(beacons.count) Beacons, \(shelves.count) Regale.")
            
        } catch {
            print("❌ JSON Fehler: \(error)")
        }
    }
    
    func startUpdateTimer() {
        updateTimer?.invalidate()
        // Alle 2 Sekunden aktualisieren (wie gewünscht)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.processBufferAndCalculate()
        }
    }
    
    func processBufferAndCalculate() {
         // Warmup Phase (erste 2 Sekunden nichts tun)
         if Date().timeIntervalSince(startTime) < 2.0 { return }
         
         for (name, values) in rssiBuffer {
             guard !values.isEmpty else { continue }
             
             // Median-Filter Logik
             let sortedValues = values.sorted()
             let filteredValues: [Int]
             if sortedValues.count >= 10 {
                 let removeCount = sortedValues.count / 5
                 filteredValues = Array(sortedValues.dropFirst(removeCount).dropLast(removeCount))
             } else {
                 filteredValues = sortedValues
             }
             
             let averageRssi = Double(filteredValues.reduce(0, +)) / Double(filteredValues.count)
             
             // Distanz & Kalman
             let rawDistance = calculateDistance(rssi: averageRssi, txPower: defaultTxPower)
             let smoothedDistance = kalmanFilters[name]?.filter(rawDistance) ?? rawDistance
             
             updateBeaconUI(name: name, rssi: Int(averageRssi), distance: smoothedDistance)
         }
         rssiBuffer.removeAll()
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
