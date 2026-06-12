import SwiftUI

struct SplashView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "map.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.cityAccent)
                    .shadow(color: .cityAccent.opacity(0.6), radius: pulse ? 24 : 8)
                    .scaleEffect(pulse ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)

                Text("CityFit")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(.white)

                Text("Your city is your gym")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.citySubtext)
            }
        }
        .onAppear { pulse = true }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
