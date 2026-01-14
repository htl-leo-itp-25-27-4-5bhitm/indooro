import Foundation
import CoreBluetooth
import Combine

class BeaconManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    
    @Published var beacons: [IndooroBeacon] = []
    
    private var centralManager: CBCentralManager?
    
    // --- RSSI PUFFER ---
    private var rssiBuffer: [String: [Int]] = [:]
    
    // --- KALMAN FILTER ---
    private var kalmanFilters: [String: KalmanFilter] = [:]
    
    // Timer für das Intervall
    private var updateTimer: Timer?
    
    // NEU: Zeitpunkt des App-Starts merken für die "Warmup-Phase"
    private let startTime = Date()
    
    // --- KONFIGURATION ---
    private let beaconCalibration: [String: Double] = [
        "Indooro1": -58.0,
        "Indooro2": -58.0,
        "Indooro3": -58.0,
        "Indooro4": -58.0,
        "Indooro5": -58.0
    ]
    
    let pathLossExp = 4.0 // 2.0 = freier Raum, 3.0-4.0 = Innenraum mit Hindernissen
    
    override init() {
        super.init()
        
        // Initialisierung der Map-Positionen
        beacons = [
            IndooroBeacon(id: "ID_1", name: "Indooro1", positionX: 0.5, positionY: 0.5),
            IndooroBeacon(id: "ID_2", name: "Indooro2", positionX: 3.5, positionY: 0.5),
            IndooroBeacon(id: "ID_3", name: "Indooro3", positionX: 3.5, positionY: 3.5),
            IndooroBeacon(id: "ID_4", name: "Indooro4", positionX: 0.5, positionY: 3.5),
            IndooroBeacon(id: "ID_5", name: "Indooro5", positionX: 2.0, positionY: 2.0)
        ]
        
        for beacon in beacons {
            kalmanFilters[beacon.name] = KalmanFilter(processNoise: 0.05, measurementNoise: 2.0)
        }
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        startUpdateTimer()
    }
    
    func startUpdateTimer() {
        updateTimer?.invalidate()
        
        // ÄNDERUNG 1: Timer läuft jetzt alle 2.0 Sekunden (statt 1.0)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.processBufferAndCalculate()
        }
    }
    
    // --- SCHRITT 1: DATEN SAMMELN (passiert kontinuierlich) ---
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name ?? "Unknown"
        
        if name.contains("Indooro") {
            let val = RSSI.intValue
            
            // Fehlerwerte filtern
            if val == 127 || val == 0 { return }
            
            // Daten IMMER sammeln, auch in der Warmup-Phase
            if rssiBuffer[name] == nil {
                rssiBuffer[name] = []
            }
            rssiBuffer[name]?.append(val)
        }
    }
    
    // --- SCHRITT 2: VERARBEITEN (alle 2 Sekunden) ---
    func processBufferAndCalculate() {
        
        // ÄNDERUNG 2: Warmup-Check
        // Wenn seit Start weniger als 2 Sekunden vergangen sind -> Abbrechen (nichts anzeigen)
        if Date().timeIntervalSince(startTime) < 2.0 {
            print("⏳ Warmup... Daten werden gesammelt.")
            return
        }
        
        for (name, values) in rssiBuffer {
            guard !values.isEmpty else { continue }
            
            // === RSSI FILTERING (Median-Mean) ===
            let sortedValues = values.sorted()
            
            let filteredValues: [Int]
            // Da wir jetzt 2 Sekunden sammeln, haben wir ca. 20 Werte.
            // Wir können also aggressiver filtern (mehr Ausreißer wegwerfen).
            if sortedValues.count >= 10 {
                // Entferne die extremsten 20% oben und unten
                let removeCount = sortedValues.count / 5
                filteredValues = Array(sortedValues.dropFirst(removeCount).dropLast(removeCount))
            } else if sortedValues.count >= 3 {
                filteredValues = Array(sortedValues.dropFirst().dropLast())
            } else {
                filteredValues = sortedValues
            }
            
            let averageRssi = Double(filteredValues.reduce(0, +)) / Double(filteredValues.count)
            
            // === DISTANZ BERECHNUNG ===
            let txPower = beaconCalibration[name] ?? -58.0
            let rawDistance = calculateDistance(rssi: averageRssi, txPower: txPower)
            
            // === KALMAN FILTER ===
            let smoothedDistance = kalmanFilters[name]?.filter(rawDistance) ?? rawDistance
            
            // === UI UPDATE ===
            updateBeaconUI(name: name, rssi: Int(averageRssi), distance: smoothedDistance)
        }
        
        // Puffer leeren für das nächste 2-Sekunden-Intervall
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
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("🟢 Bluetooth Scan startet...")
            centralManager?.scanForPeripherals(
                withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            )
        } else {
            print("🔴 Bluetooth nicht verfügbar: \(central.state.rawValue)")
        }
    }
}
