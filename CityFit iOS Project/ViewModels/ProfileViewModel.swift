import Foundation

final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var justLeveledUp = false

    var isLoggedIn: Bool { profile != nil }

    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    // MARK: - Auth (local only — no real backend)

    func createUser(username: String, character: CharacterType) {
        profile = UserProfile.new(username: username, character: character)
        save()
    }

    func logIn(username: String) {
        if profile == nil {
            // No stored account — create one with a default character
            profile = UserProfile.new(username: username, character: .sportsmanM)
        }
        save()
    }

    func logOut() {
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
        save()
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
        save()
    }

    private func updatedStreak(previous: Int) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        defer { defaults.set(today, forKey: Constants.StorageKey.lastCompletionDate) }

        guard let last = defaults.object(forKey: Constants.StorageKey.lastCompletionDate) as? Date else {
            return 1
        }
        if calendar.isDate(last, inSameDayAs: today) {
            return max(previous, 1)
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(last, inSameDayAs: yesterday) {
            return previous + 1
        }
        return 1
    }

    // MARK: - Persistence (UserDefaults)

    private func save() {
        guard let profile, let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: Constants.StorageKey.userProfile)
    }

    private func load() {
        guard let data = defaults.data(forKey: Constants.StorageKey.userProfile),
              let stored = try? JSONDecoder().decode(UserProfile.self, from: data) else { return }
        profile = stored
    }
}
