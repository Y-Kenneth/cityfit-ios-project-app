import Foundation

/// The community catalog is just mock content — only "which ones did I join" is
/// real, saved on the user's own profile (see ProfileViewModel.toggleCommunity).
@MainActor
final class CommunityViewModel: ObservableObject {
    @Published private(set) var communities: [Community] = []

    func refresh(joinedIds: [String]) {
        communities = MockData.communities.map { community in
            var updated = community
            updated.isJoined = joinedIds.contains(community.id)
            return updated
        }
    }
}
