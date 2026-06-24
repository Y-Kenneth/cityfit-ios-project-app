import SwiftUI

struct CharacterSelectView: View {
    let username: String

    @State private var selected: CharacterType = .sportsmanM
    @State private var showLoading = false

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Choose your character")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.top, 30)

                ScrollView {
                    CharacterPickerGrid(selected: $selected)
                }

                Button {
                    showLoading = true
                } label: {
                    Text("Start My Journey")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.cityAccent)
                        .cornerRadius(14)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Character")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showLoading) {
            OnboardingLoadingView(username: username, character: selected)
        }
    }
}

struct CharacterSelectView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CharacterSelectView(username: "Kenneth")
        }
    }
}
