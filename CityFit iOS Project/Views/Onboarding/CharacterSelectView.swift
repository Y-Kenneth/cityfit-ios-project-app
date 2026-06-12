import SwiftUI

struct CharacterSelectView: View {
    let username: String

    @State private var selected: CharacterType = .sportsmanM
    @State private var showLoading = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Choose your character")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.top, 30)

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(CharacterType.allCases, id: \.self) { character in
                        Button {
                            selected = character
                        } label: {
                            VStack(spacing: 10) {
                                Text(character.emoji)
                                    .font(.system(size: 52))
                                Text(character.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color.cityCard)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(selected == character ? Color.cityAccent : .clear,
                                                  lineWidth: 3)
                            )
                        }
                        .accessibilityLabel("\(character.displayName)\(selected == character ? ", selected" : "")")
                    }
                }

                Spacer()

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
