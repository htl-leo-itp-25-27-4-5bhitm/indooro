import Foundation
import CoreBluetooth
import Combine

class BeaconManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    
    @Published var beacons: [IndooroBeacon] = []
    
    private var centralManager: CBCentralManager?
    
    // --- RSSI PUFFER (sammelt alle Werte der letzten Sekunde) ---
    private var rssiBuffer: [String: [Int]] = [:]
    
    // --- KALMAN FILTER PRO BEACON (glättet die Distanzwerte) ---
    private var kalmanFilters: [String: KalmanFilter] = [:]
    
    // Timer für das 1-Sekunden-Intervall
    private var updateTimer: Timer?
    
    // --- KONFIGURATION ---
    // WICHTIG: Diese Werte müssen für jeden Beacon kalibriert werden!
    // Platziere das iPhone 1m vom Beacon entfernt und miss den durchschnittlichen RSSI
    private let beaconCalibration: [String: Double] = [
        "Indooro1": -60.0,  // ← Diese Werte musst du messen!
        "Indooro2": -60.0,
        "Indooro3": -60.0,
        "Indooro4": -60.0,
        "Indooro5": -60.0
    ]
    
    let pathLossExp = 2.0  // 2.0 = freier Raum, 3.0-4.0 = Innenraum mit Hindernissen
    
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
        
        // Initialisiere Kalman Filter für jeden Beacon
        for beacon in beacons {
            kalmanFilters[beacon.name] = KalmanFilter(
                processNoise: 0.05,      // Wie stark sich die Distanz ändern kann
                measurementNoise: 2.0     // Wie verrauscht die Messungen sind
            )
        }
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        startUpdateTimer()
    }
    
    func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
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
            
            // In Puffer speichern
            if rssiBuffer[name] == nil {
                rssiBuffer[name] = []
            }
            rssiBuffer[name]?.append(val)
        }
    }
    
    // --- SCHRITT 2: VERARBEITEN (1x pro Sekunde) ---
    func processBufferAndCalculate() {
        
        for (name, values) in rssiBuffer {
            guard !values.isEmpty else { continue }
            
            // === RSSI FILTERING (Median-Mean) ===
            let sortedValues = values.sorted()
            
            // Entferne Ausreißer bei genügend Samples
            let filteredValues: [Int]
            if sortedValues.count >= 5 {
                // Entferne schwächste und stärkste 20%
                let removeCount = max(1, sortedValues.count / 5)
                filteredValues = Array(sortedValues.dropFirst(removeCount).dropLast(removeCount))
            } else if sortedValues.count >= 3 {
                // Bei wenigen Werten nur Min/Max entfernen
                filteredValues = Array(sortedValues.dropFirst().dropLast())
            } else {
                filteredValues = sortedValues
            }
            
            // Durchschnitt berechnen
            let averageRssi = Double(filteredValues.reduce(0, +)) / Double(filteredValues.count)
            
            // === KALIBRIERUNGS-MODUS ===
            if isCalibrating {
                calibrationValues[name] = Int(averageRssi)
                updateBeaconUI(name: name, rssi: Int(averageRssi), distance: 1.0) // Zeige 1.0m an
                continue // Keine Distanzberechnung im Kalibrier-Modus
            }
            
            // === DISTANZ BERECHNUNG (Log-Distance Path Loss Model) ===
            let txPower = beaconCalibration[name] ?? -59.0
            let rawDistance = calculateDistance(rssi: averageRssi, txPower: txPower)
            
            // === KALMAN FILTER (glättet die Distanz über Zeit) ===
            let smoothedDistance = kalmanFilters[name]?.filter(rawDistance) ?? rawDistance
            
            // === UI UPDATE ===
            updateBeaconUI(name: name, rssi: Int(averageRssi), distance: smoothedDistance)
            
            // DEBUG OUTPUT (optional - auskommentieren wenn nicht benötigt)
            // print("\(name): RSSI=\(Int(averageRssi)) Raw=\(String(format: "%.2f", rawDistance))m Smooth=\(String(format: "%.2f", smoothedDistance))m")
        }
        
        // Puffer für nächste Sekunde leeren
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
        // Log-Distance Path Loss Formel:
        // distance = 10 ^ ((TxPower - RSSI) / (10 * N))
        let exponent = (txPower - rssi) / (10.0 * pathLossExp)
        return pow(10.0, exponent)
    }
    
    // === KALIBRIERUNGS-MODUS ===
    @Published var isCalibrating = false
    @Published var calibrationValues: [String: Int] = [:]
    
    func startCalibration() {
        print("🔧 KALIBRIERUNG GESTARTET")
        isCalibrating = true
        calibrationValues.removeAll()
    }
    
    func stopCalibration() {
        print("🔧 KALIBRIERUNG BEENDET")
        print("=== ERGEBNISSE ===")
        for (name, rssi) in calibrationValues.sorted(by: { $0.key < $1.key }) {
            print("\"\(name)\": \(rssi),")
        }
        isCalibrating = false
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
