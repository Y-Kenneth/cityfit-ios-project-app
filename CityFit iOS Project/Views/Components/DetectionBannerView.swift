import SwiftUI

struct DetectionBannerView: View {
    let state: CameraViewModel.DetectionState
    let message: String?

    @State private var glowPulse = false

    var body: some View {
        if let message {
            HStack(spacing: 8) {
                Image(systemName: stateIcon)
                    .font(.game(size: 14, weight: .bold))
                    .foregroundColor(borderColor)
                Text(message)
                    .font(.game(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.72))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(borderColor.opacity(glowPulse ? 1.0 : 0.5), lineWidth: 2)
            )
            .shadow(color: borderColor.opacity(glowPulse ? 0.5 : 0.1), radius: glowPulse ? 10 : 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onChange(of: state) { newState in
                if newState == .detected {
                    withAnimation(.easeInOut(duration: 0.4).repeatCount(3, autoreverses: true)) {
                        glowPulse = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        glowPulse = false
                    }
                } else {
                    glowPulse = false
                }
            }
        }
    }

    private var borderColor: Color {
        switch state {
        case .detected:  return .cityGreen
        case .possible:  return .cityYellow
        case .verifying: return .cityAccent
        case .rejected:  return .red
        case .scanning:  return Color.white.opacity(0.3)
        }
    }

    private var stateIcon: String {
        switch state {
        case .detected:  return "checkmark.circle.fill"
        case .possible:  return "questionmark.circle.fill"
        case .verifying: return "magnifyingglass.circle.fill"
        case .rejected:  return "xmark.circle.fill"
        case .scanning:  return "viewfinder"
        }
    }
}
