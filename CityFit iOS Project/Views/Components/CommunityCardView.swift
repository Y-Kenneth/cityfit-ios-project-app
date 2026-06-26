import SwiftUI

struct CommunityCardView: View {
    let community: Community
    let onJoinToggle: () -> Void
    let onDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(community.name)
                        .font(.game(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(community.memberCount) members")
                        .font(.game(size: 12))
                        .foregroundColor(.citySubtext)
                }

                Spacer()

                Button(action: onJoinToggle) {
                    Text(community.isJoined ? "Joined ✓" : "Join")
                        .font(.game(size: 13, weight: .bold))
                        .foregroundColor(community.isJoined ? .cityGreen : .black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(community.isJoined ? Color.cityGreen.opacity(0.15) : Color.cityAccent)
                        .cornerRadius(10)
                }
            }

            Text(community.description)
                .font(.game(size: 13))
                .foregroundColor(.citySubtext)

            HStack(spacing: 6) {
                ForEach(community.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.game(size: 11, weight: .medium))
                        .foregroundColor(.cityAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.cityAccent.opacity(0.12))
                        .cornerRadius(6)
                }
            }

            CommunityImageTile(imageName: community.imageName, height: 120)

            Button(action: onDetail) {
                Text("Detail")
                    .font(.game(size: 13, weight: .semibold))
                    .foregroundColor(.cityAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.cityAccent.opacity(0.12))
                    .cornerRadius(10)
            }
        }
        .padding(14)
        .background(Color.cityCard)
        .cornerRadius(16)
    }
}

struct CommunityCardView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityCardView(community: MockData.communities[0], onJoinToggle: {}, onDetail: {})
            .padding()
            .background(Color.cityBackground)
    }
}
