import SwiftUI

/// Tall standing-pose character art. Falls back to a big emoji placeholder
/// until a matching image (CharacterType.imageName) is dropped into
/// Assets.xcassets — no code change needed once that happens.
struct CharacterPortraitView: View {
    let character: CharacterType
    var width: CGFloat = 110
    var height: CGFloat = 160

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.cityAccent.opacity(0.12))
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.cityAccent.opacity(0.35), lineWidth: 1.5)

            if UIImage(named: character.imageName) != nil {
                Image(character.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(10)
            } else {
                Text(character.emoji)
                    .font(.system(size: height * 0.4))
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityLabel("\(character.displayName) character")
    }
}

struct CharacterPortraitView_Previews: PreviewProvider {
    static var previews: some View {
        CharacterPortraitView(character: .ninja)
            .padding()
            .background(Color.cityBackground)
    }
}
