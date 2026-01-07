import Foundation
import CoreBluetooth
import Combine

class BeaconManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    
    @Published var beacons: [IndooroBeacon] = []
    private var centralManager: CBCentralManager?
    
    // Konfiguration aus User Story #38
    private let txPower = -58.0 // Referenzstärke bei 1 Meter
    private let smoothingWindow = 10 // Gleitender Durchschnitt Größe
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Initialisieren wir unsere "bekannten" Beacons mit festen Positionen (Story #39)
        // Annahme: Ein Raum von ca 4x4 Metern
        beacons = [
            IndooroBeacon(id: "DUMMY_1", name: "Indooro 1", positionX: 0.5, positionY: 0.5), // Unten Links
            IndooroBeacon(id: "DUMMY_2", name: "Indooro 2", positionX: 3.5, positionY: 0.5), // Unten Rechts
            IndooroBeacon(id: "DUMMY_3", name: "Indooro 3", positionX: 3.5, positionY: 3.5), // Oben Rechts
            IndooroBeacon(id: "DUMMY_4", name: "Indooro 4", positionX: 0.5, positionY: 3.5), // Oben Links
            IndooroBeacon(id: "DUMMY_5", name: "Indooro 5", positionX: 2.0, positionY: 2.0)  // Mitte
        ]
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Scannen starten
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            print("Bluetooth Scanning gestartet...")
        } else {
            print("Bluetooth ist nicht verfügbar.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // 1. Filtern: Name muss "Indooro" enthalten (Story #38)
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name ?? "Unbekannt"
        
        if localName.contains("Indooro") {
            updateBeacon(name: localName, rssi: RSSI.intValue)
        }
    }
    
    private func updateBeacon(name: String, rssi: Int) {
        // Wir suchen den Beacon in unserer Liste (anhand des Namens)
        if let index = beacons.firstIndex(where: { $0.name == name }) {
            var beacon = beacons[index]
            
            // 2. RSSI Glätten (Moving Average - Story #38)
            beacon.rssiHistory.append(rssi)
            if beacon.rssiHistory.count > smoothingWindow {
                beacon.rssiHistory.removeFirst()
            }
            
            let sum = beacon.rssiHistory.reduce(0, +)
            beacon.smoothedRssi = Double(sum) / Double(beacon.rssiHistory.count)
            
            // 3. Distanz berechnen (Basis -58dBm - Story #38)
            // Formel: 10 ^ ((TxPower - RSSI) / (10 * n))  | n = Umweltfaktor (2-4), nehmen wir 2.0 für freien Raum
            let n = 2.0
            let exponent = (txPower - beacon.smoothedRssi) / (10 * n)
            beacon.distance = pow(10, exponent)
            
            // Update UI
            beacons[index] = beacon
        }
    }
}