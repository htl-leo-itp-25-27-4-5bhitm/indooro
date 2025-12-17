// Test der Distanzberechnung
const RSSI_AT_1M = -58;
const PATH_LOSS_EXPONENT = 2.5;

function calculateDistance(rssi) {
    console.log(`\n📊 Berechne Distanz für RSSI: ${rssi} dBm`);
    
    if (rssi === 0 || rssi > 0) {
        console.log('❌ Ungültiger RSSI (0 oder positiv)');
        return 0;
    }
    
    const exponent = (RSSI_AT_1M - rssi) / (10 * PATH_LOSS_EXPONENT);
    console.log(`   Exponent: (${RSSI_AT_1M} - ${rssi}) / (10 * ${PATH_LOSS_EXPONENT}) = ${exponent}`);
    
    const distance = Math.pow(10, exponent);
    console.log(`   Rohe Distanz: 10^${exponent} = ${distance}m`);
    
    const bounded = Math.max(0.1, Math.min(50, distance));
    console.log(`   Begrenzte Distanz: ${bounded}m`);
    
    return bounded;
}

// Test mit verschiedenen RSSI-Werten
console.log('🧪 TEST DER DISTANZBERECHNUNG');
console.log('=' .repeat(50));

const testValues = [-58, -65, -72, -78, -85];

testValues.forEach(rssi => {
    const dist = calculateDistance(rssi);
    console.log(`\n✅ RSSI ${rssi} dBm → ${dist.toFixed(2)} Meter`);
});

console.log('\n' + '='.repeat(50));
console.log('Erwartete Werte:');
console.log('-58 dBm → ~1.00m (Referenz)');
console.log('-65 dBm → ~2.24m');
console.log('-72 dBm → ~5.01m');
console.log('-78 dBm → ~10.00m');