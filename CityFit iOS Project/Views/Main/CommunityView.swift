import SwiftUI

struct CommunityView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @StateObject private var viewModel = CommunityViewModel()
    @State private var selectedCommunity: Community?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.communities) { community in
                            CommunityCardView(
                                community: community,
                                onJoinToggle: { toggleJoin(community) },
                                onDetail: { selectedCommunity = community }
                            )
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Communities")
        }
        .onAppear {
            viewModel.refresh(joinedIds: profileViewModel.profile?.joinedCommunityIds ?? [])
        }
        .sheet(item: $selectedCommunity) { community in
            CommunityDetailView(
                community: viewModel.communities.first { $0.id == community.id } ?? community,
                onJoinToggle: { toggleJoin(community) }
            )
        }
    }

    private func toggleJoin(_ community: Community) {
        profileViewModel.toggleCommunity(community.id)
        viewModel.refresh(joinedIds: profileViewModel.profile?.joinedCommunityIds ?? [])
    }
}

struct CommunityView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityView()
            .environmentObject(ProfileViewModel())
    }
}
