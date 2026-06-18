import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @ObservedObject private var authService = AuthService.shared

    @State private var appeared = false
    @State private var logoPulse = false

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()
            CityGridBackground()
            FloatingParticles()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Hero
                VStack(spacing: 20) {
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .fill(Color.cityAccent.opacity(0.08))
                            .frame(width: 160, height: 160)
                            .scaleEffect(logoPulse ? 1.15 : 1.0)
                            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: logoPulse)

                        Circle()
                            .fill(Color.cityAccent.opacity(0.15))
                            .frame(width: 120, height: 120)
                            .blur(radius: 12)

                        // Icon
                        Image(systemName: "map.fill")
                            .font(.system(size: 58, weight: .medium))
                            .foregroundColor(.cityAccent)
                            .shadow(color: .cityAccent.opacity(0.8), radius: 18, x: 0, y: 0)
                    }
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .animation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.05), value: appeared)

                    VStack(spacing: 10) {
                        Text("CityFit")
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .cityAccent.opacity(0.4), radius: 10)

                        Text("Explore your city. Level up your life.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.citySubtext)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.18), value: appeared)
                }

                Spacer()

                // MARK: Sign-in section
                VStack(spacing: 14) {
                    if let error = authService.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 13))
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
                        .font(.system(size: 11))
                        .foregroundColor(.citySubtext.opacity(0.5))
                        .multilineTextAlignment(.center)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                logoPulse = true
            }
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.label))
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

// MARK: - City Grid Background

private struct CityGridBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let spacing: CGFloat = 44

            Canvas { ctx, _ in
                let lineColor = Color.cityAccent.opacity(0.04)
                var vx = spacing
                while vx < w {
                    var p = Path()
                    p.move(to: CGPoint(x: vx, y: 0))
                    p.addLine(to: CGPoint(x: vx, y: h))
                    ctx.stroke(p, with: .color(lineColor), lineWidth: 1)
                    vx += spacing
                }
                var hy = spacing
                while hy < h {
                    var p = Path()
                    p.move(to: CGPoint(x: 0, y: hy))
                    p.addLine(to: CGPoint(x: w, y: hy))
                    ctx.stroke(p, with: .color(lineColor), lineWidth: 1)
                    hy += spacing
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Floating Particles

private struct FloatingParticles: View {
    // Fixed particle data: (xFraction, size, duration, delay, opacity)
    private let data: [(CGFloat, CGFloat, Double, Double, Double)] = [
        (0.05, 2.5, 6.0, 0.0, 0.20), (0.13, 2.0, 5.2, 1.5, 0.14),
        (0.22, 3.5, 7.0, 0.7, 0.22), (0.30, 1.5, 4.8, 2.4, 0.12),
        (0.38, 2.5, 6.5, 0.3, 0.18), (0.46, 4.0, 8.0, 1.9, 0.20),
        (0.54, 2.0, 5.5, 3.1, 0.15), (0.61, 3.0, 7.2, 0.5, 0.22),
        (0.69, 2.5, 6.0, 2.0, 0.17), (0.77, 1.5, 4.5, 1.2, 0.13),
        (0.84, 3.5, 7.8, 3.5, 0.20), (0.91, 2.0, 5.9, 0.8, 0.16),
        (0.96, 2.5, 6.2, 2.7, 0.14), (0.09, 4.0, 8.5, 1.0, 0.20),
        (0.43, 2.0, 5.0, 4.0, 0.15), (0.57, 3.0, 6.8, 0.4, 0.19),
        (0.71, 1.5, 7.0, 2.5, 0.12), (0.26, 2.5, 5.5, 3.8, 0.18),
        (0.79, 3.5, 6.3, 1.3, 0.23), (0.39, 2.0, 4.7, 0.9, 0.14),
    ]

    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ForEach(data.indices, id: \.self) { i in
                let (xFrac, size, duration, delay, opacity) = data[i]
                Circle()
                    .fill(Color.cityAccent)
                    .frame(width: size, height: size)
                    .opacity(opacity)
                    .position(
                        x: xFrac * geo.size.width,
                        y: animate ? -20 : geo.size.height + 20
                    )
                    .animation(
                        .linear(duration: duration)
                            .delay(delay)
                            .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animate = true
            }
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
