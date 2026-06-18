import Foundation
import Combine

final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var justLeveledUp = false
    @Published var isLoading = false

    var isLoggedIn: Bool { profile != nil && AuthService.shared.isSignedIn }

    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadLocal()
        AuthService.shared.$firebaseUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                if let user {
                    self?.onSignIn(uid: user.uid, displayName: user.displayName ?? "CityFitter")
                } else {
                    self?.profile = nil
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Auth

    private func onSignIn(uid: String, displayName: String) {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            if let remote = try? await FirestoreService.shared.fetchUserProfile(uid: uid) {
                profile = remote
                saveLocal()
            } else if profile == nil {
                // First sign-in — profile will be created after character selection
            }
        }
    }

    func createUser(username: String, character: CharacterType) {
        guard let uid = AuthService.shared.uid else { return }
        let newProfile = UserProfile.new(id: uid, username: username, character: character)
        profile = newProfile
        saveLocal()
        Task {
            try? await FirestoreService.shared.saveUserProfile(newProfile)
            try? await FirestoreService.shared.updateLeaderboardEntry(
                uid: uid, username: username, xp: 0, level: 1)
        }
    }

    func logOut() {
        AuthService.shared.signOut()
        profile = nil
        defaults.removeObject(forKey: Constants.StorageKey.userProfile)
    }

    // MARK: - EXP & stats

    func addEXP(_ amount: Int) {
        guard var current = profile else { return }
        let oldLevel = current.level
        current.currentEXP += amount
        current.level = EXPCalculator.level(forEXP: current.currentEXP)
        profile = current
        justLeveledUp = current.level > oldLevel
        saveLocal()
        syncToFirestore()
    }

    func recordMissionCompletion(steps: Int) {
        guard var current = profile else { return }
        current.missionsCompleted += 1
        current.totalSteps += steps
        if !current.weeklySteps.isEmpty {
            current.weeklySteps[0] += steps
        }
        current.streak = updatedStreak(previous: current.streak)
        profile = current
        saveLocal()
        syncToFirestore()
    }

    private func syncToFirestore() {
        guard let profile else { return }
        Task {
            try? await FirestoreService.shared.saveUserProfile(profile)
            try? await FirestoreService.shared.updateLeaderboardEntry(
                uid: profile.id,
                username: profile.username,
                xp: profile.currentEXP,
                level: profile.level)
        }
    }

    private func updatedStreak(previous: Int) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        defer { defaults.set(today, forKey: Constants.StorageKey.lastCompletionDate) }

        guard let last = defaults.object(forKey: Constants.StorageKey.lastCompletionDate) as? Date else {
            return 1
        }
        if calendar.isDate(last, inSameDayAs: today) { return max(previous, 1) }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(last, inSameDayAs: yesterday) {
            return previous + 1
        }
        return 1
    }

    // MARK: - Local persistence

    private func saveLocal() {
        guard let profile, let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: Constants.StorageKey.userProfile)
    }

    private func loadLocal() {
        guard let data = defaults.data(forKey: Constants.StorageKey.userProfile),
              let stored = try? JSONDecoder().decode(UserProfile.self, from: data) else { return }
        profile = stored
    }
}
