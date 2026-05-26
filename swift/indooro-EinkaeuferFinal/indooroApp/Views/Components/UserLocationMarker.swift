import SwiftUI

struct UserLocationMarker: View {
    let headingRadians: Float?
    let isReliable: Bool

    private let accent = Color(red: 0.15, green: 0.57, blue: 0.88)

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.16))
                .frame(width: 44, height: 44)

            Image(systemName: "location.north.circle.fill")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(.white, accent)
                .rotationEffect(.radians(isReliable ? Double(-(headingRadians ?? 0)) : 0))
                .shadow(color: accent.opacity(0.22), radius: 5, y: 2)
        }
        .compositingGroup()
    }
}
