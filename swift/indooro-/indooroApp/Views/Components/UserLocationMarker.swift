import SwiftUI

struct UserLocationMarker: View {
    let headingRadians: Float?

    var body: some View {
        Image(systemName: "paperplane.circle.fill")
            .font(.system(size: 34, weight: .semibold))
            .foregroundStyle(Color.white, Color.blue)
            .rotationEffect(.radians(Double(-(headingRadians ?? 0))))
            .opacity(headingRadians == nil ? 0.55 : 1)
            .shadow(color: Color.blue.opacity(0.25), radius: 3, x: 0, y: 1)
    }
}


