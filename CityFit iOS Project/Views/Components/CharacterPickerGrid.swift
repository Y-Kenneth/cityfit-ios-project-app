import SwiftUI

/// Shared character grid — used at onboarding (CharacterSelectView) and when
/// changing character later from the Profile tab (EditProfileView).
struct CharacterPickerGrid: View {
    @Binding var selected: CharacterType
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(CharacterType.allCases, id: \.self) { character in
                Button {
                    selected = character
                } label: {
                    VStack(spacing: 10) {
                        CharacterPortraitView(character: character, width: 100, height: 140)
                        Text(character.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.cityCard)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(selected == character ? Color.cityAccent : .clear, lineWidth: 3)
                    )
                }
                .accessibilityLabel("\(character.displayName)\(selected == character ? ", selected" : "")")
            }
        }
    }
}

struct CharacterPickerGrid_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            CharacterPickerGrid(selected: .constant(.sportsmanM))
                .padding()
        }
        .background(Color.cityBackground)
    }
}
