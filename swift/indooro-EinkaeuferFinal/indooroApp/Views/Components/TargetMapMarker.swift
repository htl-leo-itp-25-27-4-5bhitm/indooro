import SwiftUI

struct TargetMapMarker: View {
    @State private var pulse = false

    private let tint = Color(red: 0.15, green: 0.57, blue: 0.88)

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.14))
                .frame(width: pulse ? 52 : 40, height: pulse ? 52 : 40)
                .opacity(pulse ? 0.18 : 0.36)

            VStack(spacing: -3) {
                Image(systemName: "cart.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white, tint)
                    .shadow(color: tint.opacity(0.22), radius: 6, y: 3)

                Circle()
                    .fill(tint)
                    .frame(width: 7, height: 7)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
