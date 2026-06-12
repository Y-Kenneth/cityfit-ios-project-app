import SwiftUI

/// App entry flow: Splash → (Login / SignUp / Onboarding) → MainTabView.
/// Owns the shared view models injected into the environment.
struct RootView: View {
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var missionViewModel = MissionViewModel()
    @StateObject private var aiViewModel = AIViewModel()
    @StateObject private var locationService = LocationService()

    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if profileViewModel.isLoggedIn {
                MainTabView()
                    .transition(.opacity)
            } else {
                NavigationStack {
                    LoginView()
                }
                .transition(.opacity)
            }
        }
        .environmentObject(profileViewModel)
        .environmentObject(missionViewModel)
        .environmentObject(aiViewModel)
        .environmentObject(locationService)
        .preferredColorScheme(.dark)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
