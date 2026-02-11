import SwiftUI

struct BeaconMapItem: View {
    let beacon: IndooroBeacon
    let pixelsPerMeter: Double
    
    var statusColor: Color {
        if beacon.distance <= 0 { return .gray.opacity(0.3) }
        if beacon.distance < 2.0 { return .green }
        return .orange
    }
    
    var body: some View {
        ZStack {
            // Radar-Kreis (nur wenn Signal da ist)
            if beacon.distance > 0 && beacon.distance < 10 {
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
                    .frame(
                        width: CGFloat(beacon.distance * pixelsPerMeter * 2),
                        height: CGFloat(beacon.distance * pixelsPerMeter * 2)
                    )
            }
            
            // Icon
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 14))
                .foregroundColor(statusColor)
                .background(Circle().fill(.white).frame(width: 20, height: 20))
                .shadow(radius: 1)
            
            Text(beacon.name)
                .font(.system(size: 7))
                .offset(y: 12)
        }
    }
}
