import SwiftUI
import CoreLocation

/// The user's own map pin: character emoji in a fixed-upright circle, with a
/// "cone of vision" wedge that rotates to match the device's real compass
/// heading — same convention as Apple/Google Maps' own blue dot.
struct UserAvatarPinView: View {
    let emoji: String
    let heading: CLLocationDirection

    var body: some View {
        ZStack {
            HeadingCone()
                .fill(Color.cityAccent.opacity(0.85))
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(heading))

            Circle()
                .fill(Color.cityAccent.opacity(0.2))
                .frame(width: 48, height: 48)
            Circle()
                .fill(Color.cityCard)
                .frame(width: 40, height: 40)
            Circle()
                .strokeBorder(Color.cityAccent, lineWidth: 2.5)
                .frame(width: 40, height: 40)
            Text(emoji)
                .font(.game(size: 19))
        }
        .frame(width: 64, height: 64)
    }
}

/// A narrow wedge pointing up (north) from the circle's edge outward —
/// rotated by `heading` degrees to show which way the user is facing.
private struct HeadingCone: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let tip = CGPoint(x: rect.midX, y: rect.minY)
        let left = CGPoint(x: rect.midX - rect.width * 0.16, y: rect.midY - rect.height * 0.05)
        let right = CGPoint(x: rect.midX + rect.width * 0.16, y: rect.midY - rect.height * 0.05)

        var path = Path()
        path.move(to: tip)
        path.addLine(to: right)
        path.addLine(to: center)
        path.addLine(to: left)
        path.closeSubpath()
        return path
    }
}

struct UserAvatarPinView_Previews: PreviewProvider {
    static var previews: some View {
        UserAvatarPinView(emoji: "🐰", heading: 45)
            .padding()
            .background(Color.cityBackground)
    }
}
