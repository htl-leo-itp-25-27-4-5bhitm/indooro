import asyncio
from bleak import BleakScanner

async def scan():
    print("🔍 Scanne 10 Sekunden nach BLE-Geräten...")
    print("⚠️ Bitte als Administrator ausführen!\n")
    
    try:
        devices = await BleakScanner.discover(timeout=10.0, return_adv=True)
        
        print(f"✅ Gefunden: {len(devices)} Geräte\n")
        print("=" * 70)
        
        for addr, (device, adv_data) in devices.items():
            name = device.name or "Unbekannt"
            rssi = adv_data.rssi
            
            print(f"📱 {name}")
            print(f"   MAC: {addr}")
            print(f"   RSSI: {rssi} dBm")
            
            # Zeige ob es ein Indooro Beacon ist
            if "Indooro" in name or "indooro" in name.lower():
                print(f"   🎯 ← DAS IST EIN INDOORO BEACON!")
            
            print("-" * 70)
            
    except PermissionError:
        print("❌ FEHLER: Keine Berechtigung!")
        print("→ Starte die Eingabeaufforderung als Administrator!")
    except Exception as e:
        print(f"❌ Fehler: {e}")

if __name__ == "__main__":
    asyncio.run(scan())