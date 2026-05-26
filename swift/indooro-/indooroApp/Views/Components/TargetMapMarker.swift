import SwiftUI

struct TargetMapMarker: View {
    @State private var bounce = false
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.red)
                .background(Circle().fill(.white))
                .shadow(radius: 3)
            
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundColor(.red)
                .offset(y: -5)
        }
        .offset(y: bounce ? -10 : 0)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                bounce = true
            }
        }
    }
}
