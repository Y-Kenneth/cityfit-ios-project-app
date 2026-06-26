import SwiftUI

struct SplashView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            AppBackgroundView()

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .shadow(color: .cityAccent.opacity(pulse ? 0.6 : 0.2), radius: pulse ? 24 : 8)
                .scaleEffect(pulse ? 1.04 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
        }
        .onAppear { pulse = true }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
