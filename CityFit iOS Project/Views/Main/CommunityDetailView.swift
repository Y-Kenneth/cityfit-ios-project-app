import SwiftUI

struct CommunityDetailView: View {
    let community: Community
    let onJoinToggle: () -> Void

    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var showChat = false

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Capsule()
                        .fill(Color.citySubtext.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)

                    CommunityImageTile(imageName: community.imageName, height: 180)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(community.name)
                            .font(.game(size: 26, weight: .heavy))
                            .foregroundColor(.white)
                        Text("\(community.memberCount) members")
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

                        Text(community.longDescription)
                            .font(.game(size: 15))
                            .foregroundColor(.citySubtext)
                    }

                    Button(action: onJoinToggle) {
                        Text(community.isJoined ? "Leave Community" : "Join Community")
                            .font(.game(size: 16, weight: .bold))
                            .foregroundColor(community.isJoined ? .red : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(community.isJoined ? Color.red.opacity(0.15) : Color.cityAccent)
                            .cornerRadius(12)
                    }

                    if community.isJoined {
                        Button {
                            showChat = true
                        } label: {
                            Label("Open Chat", systemImage: "bubble.left.and.bubble.right.fill")
                                .font(.game(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.cityAccent)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(20)
            }
        }
        .presentationDetents([.medium, .large])
        .fullScreenCover(isPresented: $showChat) {
            if let profile = profileViewModel.profile {
                CommunityChatView(community: community, profile: profile)
                    .environmentObject(profileViewModel)
            }
        }
    }

}

struct CommunityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityDetailView(community: MockData.communities[0], onJoinToggle: {})
            .environmentObject(ProfileViewModel())
    }
}
