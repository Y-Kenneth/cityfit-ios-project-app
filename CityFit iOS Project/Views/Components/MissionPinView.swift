import SwiftUI

struct MissionPinView: View {
    let pin: MapPinItem
    var onTap: (() -> Void)? = nil

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(pin.color.opacity(0.25))
                    .frame(width: 52, height: 52)
                Circle()
                    .fill(pin.color)
                    .frame(width: 36, height: 36)
                Image(systemName: pin.icon)
                    .font(.game(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
            .scaleEffect(isPressed ? 1.2 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
            .onTapGesture {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressed = false
                    onTap?()
                }
            }

            Text(pin.title)
                .font(.game(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.75))
                .cornerRadius(4)
        }
        .accessibilityLabel("\(pin.kind == .mission ? "Mission" : "Event"): \(pin.title)")
    }
}
