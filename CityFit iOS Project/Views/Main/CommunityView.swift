import SwiftUI

/// Mock communities — join state toggles locally only.
struct CommunityView: View {
    @State private var communities = MockData.communities
    @State private var selectedCommunity: Community?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cityBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(communities) { community in
                            Button {
                                selectedCommunity = community
                            } label: {
                                CommunityCardView(community: community) {
                                    toggleJoin(community)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Communities")
        }
        .sheet(item: $selectedCommunity) { community in
            CommunityDetailView(
                community: communities.first { $0.id == community.id } ?? community
            ) {
                toggleJoin(community)
            }
        }
    }

    private func toggleJoin(_ community: Community) {
        guard let index = communities.firstIndex(where: { $0.id == community.id }) else { return }
        communities[index].isJoined.toggle()
    }
}

struct CommunityView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityView()
    }
}
