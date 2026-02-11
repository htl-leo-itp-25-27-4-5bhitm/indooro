import SwiftUI

struct UserLocationMarker: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Pulsierender äußerer Kreis
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .scaleEffect(isPulsing ? 1.2 : 0.8)
                .opacity(isPulsing ? 0.0 : 0.5)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                        isPulsing = true
                    }
                }
            
            // Fester Kern
            Circle()
                .fill(Color.blue)
                .frame(width: 15, height: 15)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(radius: 2)
            
            Text("ICH")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.blue)
                .offset(y: -16)
        }
    }
}
