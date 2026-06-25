import Foundation
import Combine
import UIKit

final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var justLeveledUp = false
    @Published var isLoading = false

    #if DEBUG
    @Published private(set) var debugBypassActive = false
    private let debugBypassKey = "cityfit.debug.bypassAuth"
    #endif

    var isLoggedIn: Bool {
        #if DEBUG
        if debugBypassActive { return profile != nil }
        #endif
        return profile != nil && AuthService.shared.isSignedIn
    }

    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    init() {
        #if DEBUG
        debugBypassActive = defaults.bool(forKey: debugBypassKey)
        #endif
        loadLocal()
        AuthService.shared.$firebaseUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                if let user {
                    self?.onSignIn(uid: user.uid, displayName: user.displayName ?? "CityFitter")
                } else {
                    #if DEBUG
                    if self?.debugBypassActive == true { return }
                    #endif
                    self?.profile = nil
                }
            }
            .store(in: &cancellables)
    }

    #if DEBUG
    /// Skips Google Sign-In entirely for local testing: creates (or reuses) a
    /// local-only profile with no Firebase Auth session. Debug builds only —
    /// stripped out of Release, so it can't ship.
    func debugSkipLogin() {
        debugBypassActive = true
        defaults.set(true, forKey: debugBypassKey)
        if profile == nil {
            profile = UserProfile.new(id: "debug-user", username: "Debug Tester", character: .sportsmanM)
            saveLocal()
        }
    }
    #endif

    // MARK: - Auth

    private func onSignIn(uid: String, displayName: String) {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            // If this device already has a local profile for this exact user,
            // treat it as authoritative — it's where mutations land first, so
            // pushing it up is safer than pulling remote and risking clobbering
            // newer local progress with a stale (e.g. previously failed-to-sync)
            // cloud copy. Only pull from remote on a device that has nothing
            // cached yet for this user.
            if let local = profile, local.id == uid {
                _ = await syncToFirestore()
            } else if let remote = try? await FirestoreService.shared.fetchUserProfile(uid: uid) {
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
        scheduleSync()
    }

    func logOut() {
        AuthService.shared.signOut()
        profile = nil
        defaults.removeObject(forKey: Constants.StorageKey.userProfile)
        #if DEBUG
        debugBypassActive = false
        defaults.removeObject(forKey: debugBypassKey)
        #endif
    }

    // MARK: - Editing

    func updateProfile(username: String, character: CharacterType) {
        guard var current = profile else { return }
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        current.username = trimmed
        current.character = character
        profile = current
        saveLocal()
        scheduleSync()
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
        scheduleSync()

        if justLeveledUp {
            VoiceCoachService.shared.speakNow("Level up! You're now level \(current.level).")
        } else {
            VoiceCoachService.shared.speak("Plus \(amount) experience.")
        }
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
        scheduleSync()
    }

    // MARK: - Communities

    /// Saved on the user's own profile doc — no cross-user reads involved, so
    /// this doesn't depend on Firestore rules permitting broad collection access.
    func toggleCommunity(_ communityId: String) {
        guard var current = profile else { return }
        if let index = current.joinedCommunityIds.firstIndex(of: communityId) {
            current.joinedCommunityIds.remove(at: index)
        } else {
            current.joinedCommunityIds.append(communityId)
        }
        profile = current
        saveLocal()
        scheduleSync()
    }

    /// Pushes `profile` to Firestore on a background-extended Task so a sync
    /// in flight when the user backgrounds the app (e.g. right after finishing
    /// a mission) gets a few extra seconds to complete instead of being cut off
    /// immediately. Errors are logged, not swallowed — check the console if
    /// progress stops showing up across devices.
    private func scheduleSync() {
        guard profile != nil else { return }
        var taskId: UIBackgroundTaskIdentifier = .invalid
        taskId = UIApplication.shared.beginBackgroundTask(withName: "ProfileSync") {
            UIApplication.shared.endBackgroundTask(taskId)
            taskId = .invalid
        }
        Task {
            defer {
                if taskId != .invalid { UIApplication.shared.endBackgroundTask(taskId) }
            }
            _ = await syncToFirestore()
        }
    }

    @discardableResult
    private func syncToFirestore() async -> Bool {
        guard let profile else { return false }
        do {
            try await FirestoreService.shared.saveUserProfile(profile)
            try await FirestoreService.shared.updateLeaderboardEntry(
                uid: profile.id,
                username: profile.username,
                xp: profile.currentEXP,
                level: profile.level)
            return true
        } catch {
            print("⚠️ ProfileViewModel: Firestore sync failed for \(profile.id) — \(error.localizedDescription)")
            return false
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
