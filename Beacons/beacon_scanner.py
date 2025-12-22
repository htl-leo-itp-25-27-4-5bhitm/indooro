import asyncio
import json
from bleak import BleakScanner
import websockets

WS_URI = "ws://localhost:8080"
BEACON_NAMES = ["Indooro1", "Indooro2", "Indooro3", "Indooro4", "Indooro5"]

async def scan_loop():
    print("🟢 Starte BLE-Scanning…")

    async with websockets.connect(WS_URI) as ws:
        print("🔗 Verbunden mit Node.js WebSocket")

        def detection_callback(device, advertisement_data):
            if device.name in BEACON_NAMES:
                rssi = advertisement_data.rssi
                if rssi is None:
                    return

                payload = {
                    "id": device.address,
                    "name": device.name,
                    "rssi": int(rssi)
                }

                asyncio.create_task(ws.send(json.dumps(payload)))

        scanner = BleakScanner(detection_callback)
        await scanner.start()

        try:
            while True:
                await asyncio.sleep(1)
        except KeyboardInterrupt:
            print("⛔ Beendet durch Benutzer")
        finally:
            await scanner.stop()

asyncio.run(scan_loop())
