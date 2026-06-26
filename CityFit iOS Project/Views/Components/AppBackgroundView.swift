import SwiftUI

/// Shared "city at night" backdrop — solid dark base, a faint perspective
/// grid, and slowly rising particles. Originally built for LoginView; reused
/// across every other non-map, non-camera screen for a consistent atmosphere.
struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()
            CityGridBackground()
            FloatingParticles()
        }
    }
}

// MARK: - City Grid Background

struct CityGridBackground: View {
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

struct FloatingParticles: View {
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
