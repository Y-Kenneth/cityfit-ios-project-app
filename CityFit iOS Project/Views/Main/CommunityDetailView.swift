import SwiftUI

struct CommunityDetailView: View {
    let community: Community
    let onJoinToggle: () -> Void

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Capsule()
                        .fill(Color.citySubtext.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(community.name)
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(.white)
                        Text("\(community.memberCount) members")
                            .font(.system(size: 13))
                            .foregroundColor(.citySubtext)
                        Text(community.description)
                            .font(.system(size: 15))
                            .foregroundColor(.citySubtext)
                    }

                    Button(action: onJoinToggle) {
                        Text(community.isJoined ? "Leave Community" : "Join Community")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(community.isJoined ? .red : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(community.isJoined ? Color.red.opacity(0.15) : Color.cityAccent)
                            .cornerRadius(12)
                    }
                }
                .padding(20)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct CommunityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityDetailView(community: MockData.communities[0], onJoinToggle: {})
    }
}
