import SwiftUI

struct CharacterAvatarView: View {
    let character: CharacterType
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.cityAccent.opacity(0.15))
            Circle()
                .strokeBorder(Color.cityAccent, lineWidth: 2)
            Text(character.emoji)
                .font(.game(size: size * 0.5))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("\(character.displayName) character")
    }
}

struct CharacterAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        CharacterAvatarView(character: .rabbit)
            .padding()
            .background(Color.cityBackground)
    }
}
