import SwiftUI

/// Green / yellow / red detection overlay banner for photo missions.
struct DetectionBannerView: View {
    let state: CameraViewModel.DetectionState
    let message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(borderColor, lineWidth: 2)
                )
                .transition(.opacity)
        }
    }

    private var borderColor: Color {
        switch state {
        case .detected:  return .cityGreen
        case .possible:  return .cityYellow
        case .verifying: return .cityAccent
        case .rejected:  return .red
        case .scanning:  return .clear
        }
    }
}
