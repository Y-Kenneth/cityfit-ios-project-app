import SwiftUI

/// Mock leaderboard — static fake users with the current user at rank 5.
/// Tapping any row opens UserDetailView with that user's health stats, so
/// the Ranks tab surfaces more than just rank/EXP — mirrors how
/// CommunityDetailView opens from a CommunityCardView tap.
struct LeaderboardView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var selectedEntry: LeaderboardEntry?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cityBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(entries) { entry in
                            Button {
                                selectedEntry = entry
                            } label: {
                                LeaderboardRowView(entry: entry,
                                                   isCurrentUser: entry.rank == MockData.currentUserRank)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Leaderboard")
        }
        .sheet(item: $selectedEntry) { entry in
            UserDetailView(entry: entry, isCurrentUser: entry.rank == MockData.currentUserRank)
        }
    }

    /// Replace the rank-5 placeholder with the real local user, including
    /// their actual health stats instead of the mock placeholder values.
    private var entries: [LeaderboardEntry] {
        MockData.leaderboard.map { entry in
            guard entry.rank == MockData.currentUserRank,
                  let profile = profileViewModel.profile else { return entry }
            return LeaderboardEntry(rank: entry.rank,
                                    username: profile.username,
                                    exp: profile.currentEXP,
                                    level: profile.level,
                                    character: profile.character,
                                    gender: profile.gender,
                                    weightKg: profile.weightKg,
                                    heightCm: profile.heightCm,
                                    restingHeartRate: profile.restingHeartRate,
                                    activeEnergyKcal: profile.activeEnergyKcal,
                                    streak: profile.streak,
                                    totalSteps: profile.totalSteps)
        }
    }
}

struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView()
            .environmentObject(ProfileViewModel())
    }
}
