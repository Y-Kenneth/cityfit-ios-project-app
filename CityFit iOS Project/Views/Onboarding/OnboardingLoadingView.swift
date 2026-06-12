import SwiftUI

struct OnboardingLoadingView: View {
    let username: String
    let character: CharacterType

    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var spin = false

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Text(character.emoji)
                    .font(.system(size: 72))

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 28))
                    .foregroundColor(.cityAccent)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: spin)

                Text("Building your city…")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.citySubtext)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            spin = true
            // Creating the profile flips RootView to MainTabView
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                profileViewModel.createUser(
                    username: username.isEmpty ? "CityFitter" : username,
                    character: character
                )
            }
        }
    }
}

struct OnboardingLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingLoadingView(username: "Kenneth", character: .rabbit)
            .environmentObject(ProfileViewModel())
    }
}
