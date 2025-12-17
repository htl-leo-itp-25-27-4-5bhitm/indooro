const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const WebSocket = require('ws');

const app = express();
const server = http.createServer(app);
const io = new Server(server);
const wss = new WebSocket.Server({ port: 8080 });

const PORT = 3000;
app.use(express.static('public'));

// Datenstruktur
const samples = new Map();
const lastKnownBeacons = new Map();  // ✅ Speichert letzte bekannte Beacon-Daten
const AVERAGE_WINDOW_MS = 1000;
const BEACON_TIMEOUT_MS = 10000;  // ✅ Beacon bleibt 10 Sekunden sichtbar ohne Updates

// ✅ Filter für erlaubte Beacon-Namen
const ALLOWED_BEACONS = ["Indooro1", "Indooro2", "Indooro3", "Indooro4", "Indooro5"];

// 📐 Kalibrierungswerte
const RSSI_AT_1M = -58;
const PATH_LOSS_EXPONENT = 3.5;

console.log('═'.repeat(70));
console.log('📐 KALIBRIERUNG');
console.log('═'.repeat(70));
console.log(`RSSI @ 1m: ${RSSI_AT_1M} dBm`);
console.log(`Path Loss Exponent: ${PATH_LOSS_EXPONENT}`);
console.log(`Beacon Timeout: ${BEACON_TIMEOUT_MS / 1000}s`);
console.log('═'.repeat(70));

function calculateDistance(rssi) {
    if (typeof rssi !== 'number' || isNaN(rssi)) return null;
    if (rssi === 0 || rssi > 0) return null;
    
    const exponent = (RSSI_AT_1M - rssi) / (10 * PATH_LOSS_EXPONENT);
    const distance = Math.pow(10, exponent);
    return Math.max(0.1, Math.min(50, distance));
}

function addSample(id, rssi, name) {
    if (!samples.has(id)) samples.set(id, []);
    samples.get(id).push({ rssi, name, ts: Date.now() });
}

// WebSocket von Python
wss.on('connection', ws => {
    console.log('\n✅ Python Beacon-Scanner verbunden\n');
    
    ws.on('message', msg => {
        try {
            const data = JSON.parse(msg);
            
            if (ALLOWED_BEACONS.includes(data.name)) {
                addSample(data.id, data.rssi, data.name);
                const distance = calculateDistance(data.rssi);
                
                if (distance !== null && !isNaN(distance)) {
                    console.log(`📡 ${data.name}: ${data.rssi} dBm → ${distance.toFixed(2)}m`);
                }
            }
        } catch (err) {
            console.error("❌ Fehler:", err.message);
        }
    });
    
    ws.on('close', () => {
        console.log("\n⚠️ Python Beacon-Scanner getrennt\n");
    });
});

// Durchschnitt berechnen und senden
// Durchschnitt berechnen und senden
setInterval(() => {
    const now = Date.now();
    const result = [];

    for (const [id, arr] of samples.entries()) {
        const windowSamples = arr.filter(s => now - s.ts <= AVERAGE_WINDOW_MS);
        if (windowSamples.length === 0) continue;

        // Median berechnen
        const values = windowSamples.map(s => s.rssi);
        const median = values.sort((a,b)=>a-b)[Math.floor(values.length/2)];

        // ✅ Filter gegen Ausreißer (Störfilter)
        const filtered = windowSamples.filter(s => Math.abs(s.rssi - median) <= 8); // war 5

        // Mittelwert der gefilterten Samples
        const avg = filtered.reduce((acc, s) => acc + s.rssi, 0) / filtered.length;

        // Optional: EMA Glättung
        const last = lastKnownBeacons.get(id);
        const alpha = 0.3; // 0=langsam, 1=reaktiv
        const smoothedAvg = last ? avg * alpha + last.avgRssi * (1 - alpha) : avg;

        const name = filtered[filtered.length - 1].name;
        const distance = calculateDistance(smoothedAvg);

        if (distance !== null && !isNaN(distance) && isFinite(distance)) {
            const entry = { 
                id, 
                name,
                avgRssi: Math.round(smoothedAvg * 100) / 100, 
                distance: Math.round(distance * 100) / 100,
                count: filtered.length,
                lastSeen: now,
                active: true
            };
            
            lastKnownBeacons.set(id, entry);
            result.push(entry);
        }

        samples.set(id, windowSamples);
    }

    // Alte Beacons hinzufügen wie bisher
    for (const [id, beacon] of lastKnownBeacons.entries()) {
        const timeSinceLastSeen = now - beacon.lastSeen;
        if (result.find(b => b.id === id)) continue;
        if (timeSinceLastSeen > BEACON_TIMEOUT_MS) {
            console.log(`⏰ ${beacon.name} timeout (${(timeSinceLastSeen/1000).toFixed(0)}s)`);
            lastKnownBeacons.delete(id);
            continue;
        }
        result.push({
            ...beacon,
            active: false,
            secondsSinceUpdate: Math.round(timeSinceLastSeen / 1000)
        });
    }

    if (result.length > 0) {
        result.sort((a, b) => a.distance - b.distance);
        const debug = result.map(r => `${r.name}:${r.distance}m${r.active ? '' : '(alt)'}`).join(', ');
        console.log(`📤 [${debug}]`);

        io.emit('averages', { 
            ts: now, 
            values: result
        });
    }
}, AVERAGE_WINDOW_MS);


// Socket.io für Browser
io.on('connection', socket => {
    console.log('🌐 Browser verbunden:', socket.id);
    
    socket.emit('calibration', {
        rssiAt1m: RSSI_AT_1M,
        pathLoss: PATH_LOSS_EXPONENT
    });
    
    // ✅ Sende sofort alle bekannten Beacons
    if (lastKnownBeacons.size > 0) {
        const beacons = Array.from(lastKnownBeacons.values());
        socket.emit('averages', {
            ts: Date.now(),
            values: beacons
        });
    }
});

server.listen(PORT, () => {
    console.log(`\n✅ HTTP Server läuft: http://localhost:${PORT}`);
    console.log(`✅ WebSocket Server läuft: ws://localhost:8080\n`);
});