import SwiftUI

/// Shows a community's header photo from the Asset Catalog, or a placeholder
/// tile if `imageName` is nil or no matching asset has been added yet — drop
/// an image into Assets.xcassets under that name and it appears automatically,
/// no call site changes needed.
struct CommunityImageTile: View {
    let imageName: String?
    var height: CGFloat = 160

    var body: some View {
        Group {
            if let imageName, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
        .cornerRadius(16)
    }

    private var placeholder: some View {
        ZStack {
            Color.cityCard
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 28))
                .foregroundColor(.citySubtext.opacity(0.5))
        }
    }
}

struct CommunityImageTile_Previews: PreviewProvider {
    static var previews: some View {
        CommunityImageTile(imageName: nil)
            .padding()
            .background(Color.cityBackground)
    }
}
