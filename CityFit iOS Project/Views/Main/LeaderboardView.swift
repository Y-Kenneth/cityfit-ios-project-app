import SwiftUI

/// Mock leaderboard — static fake users with the current user at rank 5.
struct LeaderboardView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cityBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(entries) { entry in
                            LeaderboardRowView(entry: entry,
                                               isCurrentUser: entry.rank == MockData.currentUserRank)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Leaderboard")
        }
    }

    /// Replace the rank-5 placeholder with the real local user.
    private var entries: [LeaderboardEntry] {
        MockData.leaderboard.map { entry in
            guard entry.rank == MockData.currentUserRank,
                  let profile = profileViewModel.profile else { return entry }
            return LeaderboardEntry(rank: entry.rank,
                                    username: profile.username,
                                    exp: profile.currentEXP,
                                    level: profile.level,
                                    character: profile.character)
        }
    }
}

struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView()
            .environmentObject(ProfileViewModel())
    }
}
