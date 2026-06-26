import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @ObservedObject private var authService = AuthService.shared

    @State private var appeared = false

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Hero
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .frame(maxWidth: .infinity)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .animation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.05), value: appeared)

                Spacer()

                // MARK: Sign-in section
                VStack(spacing: 14) {
                    if let error = authService.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.game(size: 13))
                                .foregroundColor(.red.opacity(0.9))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    GoogleSignInButton(isLoading: authService.isLoading || profileViewModel.isLoading) {
                        Task { await signInWithGoogle() }
                    }

                    Text("By continuing, you agree to our Terms of Service")
                        .font(.game(size: 11))
                        .foregroundColor(.citySubtext.opacity(0.5))
                        .multilineTextAlignment(.center)

                    #if DEBUG
                    Button("Skip Login (Debug)") {
                        profileViewModel.debugSkipLogin()
                    }
                    .font(.game(size: 13, weight: .semibold))
                    .foregroundColor(.cityAccent.opacity(0.7))
                    .padding(.top, 6)
                    #endif
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 52)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 40)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.32), value: appeared)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            appeared = true
        }
    }

    private func signInWithGoogle() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        await AuthService.shared.signInWithGoogle(presentingViewController: root)
    }
}

// MARK: - Google Sign-In Button

private struct GoogleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: { guard !isLoading else { return }; action() }) {
            HStack(spacing: 14) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(.systemGray)))
                        .frame(width: 22, height: 22)
                } else {
                    GoogleGIcon()
                        .frame(width: 22, height: 22)
                }

                Text(isLoading ? "Signing in…" : "Continue with Google")
                    .font(.game(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.235, green: 0.247, blue: 0.263)) // fixed dark gray — .label resolves to white under the app's forced dark scheme
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.cityAccent.opacity(isPressed ? 0.3 : 0.15),
                            radius: isPressed ? 6 : 14, x: 0, y: isPressed ? 2 : 6)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Google G Icon (drawn with Canvas)

private struct GoogleGIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let r  = min(size.width, size.height) / 2
            let lw = r * 0.38
            let ar = r - lw / 2

            let blue   = Color(red: 0.26, green: 0.52, blue: 0.96)
            let red    = Color(red: 0.92, green: 0.26, blue: 0.21)
            let yellow = Color(red: 1.00, green: 0.76, blue: 0.03)
            let green  = Color(red: 0.20, green: 0.66, blue: 0.33)
            let center = CGPoint(x: cx, y: cy)

            // Arc segments (clockwise, 0° = right, 90° = down)
            // Gap is at the right side (~-25° to 25°)
            let segs: [(Color, Double, Double)] = [
                (blue,   25, 155),   // right → bottom-right
                (red,   155, 248),   // bottom → left
                (yellow,248, 295),   // left → upper-left
                (green, 295, 335),   // upper-left → top
            ]

            for (color, start, end) in segs {
                var p = Path()
                p.addArc(center: center, radius: ar,
                         startAngle: .degrees(start), endAngle: .degrees(end),
                         clockwise: false)
                ctx.stroke(p, with: .color(color),
                           style: StrokeStyle(lineWidth: lw, lineCap: .butt))
            }

            // Blue top arc (gap area closes toward top)
            var topArc = Path()
            topArc.addArc(center: center, radius: ar,
                          startAngle: .degrees(335), endAngle: .degrees(385),
                          clockwise: false)
            ctx.stroke(topArc, with: .color(blue),
                       style: StrokeStyle(lineWidth: lw, lineCap: .butt))

            // Crossbar (blue horizontal bar, right half only)
            var bar = Path()
            bar.move(to: CGPoint(x: cx, y: cy))
            bar.addLine(to: CGPoint(x: cx + ar + lw / 2, y: cy))
            ctx.stroke(bar, with: .color(blue),
                       style: StrokeStyle(lineWidth: lw * 0.72, lineCap: .round))
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoginView()
        }
        .environmentObject(ProfileViewModel())
    }
}
