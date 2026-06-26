import Foundation

final class MissionViewModel: ObservableObject {
    @Published var missions: [Mission] = []
    @Published var activeMission: Mission?

    private let defaults = UserDefaults.standard

    init() {
        load()
        expireCooldowns()
    }

    var availableMissions: [Mission] { missions.filter { $0.status == .available } }
    var completedMissions: [Mission] { missions.filter { $0.status == .completed } }
    var cooldownMissions: [Mission] { missions.filter { $0.status == .cooldown } }

    /// Missions with a map pin that are still playable.
    var pinnedMissions: [Mission] {
        missions.filter { $0.coordinate != nil && $0.status != .completed }
    }

    /// The mission shown on the Home bottom card.
    var featuredMission: Mission? {
        activeMission ?? availableMissions.first
    }

    // MARK: - Lifecycle

    func start(_ mission: Mission) {
        var started = mission
        started.status = .active
        started.currentValue = 0
        update(started)
        activeMission = started
    }

    func updateActiveProgress(_ value: Double) {
        guard var mission = activeMission else { return }
        // Photo missions count captured objects via incrementPhotoProgress, not
        // steps/distance. When a photo mission is picked mid-walk it becomes the
        // active mission, but the walk's per-second tick keeps calling this with
        // its own step/distance value (0 for a plain walk) — which would reset
        // the capture count to 0 every tick, making the mission uncompletable.
        guard mission.type != .photo else { return }
        let previousFraction = mission.targetValue > 0 ? mission.currentValue / mission.targetValue : 0
        mission.currentValue = value
        activeMission = mission
        update(mission)
        announceProgress(mission: mission, previousFraction: previousFraction)
    }

    /// One-time callout every 10% an active mission's progress crosses — not on
    /// every tick, just the moment it crosses into a new decile. 100% is left to
    /// the completion/EXP callout instead of being announced here too.
    private func announceProgress(mission: Mission, previousFraction: Double) {
        guard mission.targetValue > 0 else { return }
        let fraction = min(mission.currentValue / mission.targetValue, 1.0)
        guard fraction < 1.0 else { return }

        let previousDecile = Int(previousFraction * 10)
        let currentDecile = Int(fraction * 10)
        guard currentDecile > previousDecile else { return }

        VoiceCoachService.shared.speak("\(currentDecile * 10) percent through \(mission.title).")
    }

    /// Passive walking missions — all available step/distance missions that the
    /// user is NOT actively tracking but whose progress can advance in the background.
    var passiveWalkingMissions: [Mission] {
        missions.filter {
            $0.status == .available &&
            ($0.type == .steps || $0.type == .distance) &&
            $0.id != activeMission?.id
        }
    }

    /// Photo-capture missions available to pick from the in-walk camera icon.
    var availablePhotoMissions: [Mission] {
        missions.filter { $0.status == .available && $0.type == .photo }
    }

    /// Updates every passive walking mission with the current pedometer/GPS value.
    /// Completes any that cross the target and returns the total EXP earned.
    @discardableResult
    func updatePassiveProgress(steps: Int, distance: Double, multiplier: Double = 1.0) -> [(mission: Mission, exp: Int)] {
        var earned: [(Mission, Int)] = []
        for index in missions.indices {
            guard missions[index].status == .available,
                  missions[index].id != activeMission?.id else { continue }
            let type = missions[index].type
            guard type == .steps || type == .distance else { continue }

            let value = type == .steps ? Double(steps) : distance
            missions[index].currentValue = min(value, missions[index].targetValue)

            if missions[index].currentValue >= missions[index].targetValue {
                let exp = Int(Double(missions[index].expReward) * max(multiplier, 1.0))
                missions[index].status = .cooldown
                missions[index].cooldownUntil = Date().addingTimeInterval(
                    Constants.missionCooldownHours * 3600)
                earned.append((missions[index], exp))
            }
        }
        save()
        return earned
    }

    func incrementPhotoProgress() {
        guard var mission = activeMission, mission.type == .photo else { return }
        mission.currentValue = min(mission.currentValue + 1, mission.targetValue)
        activeMission = mission
        update(mission)
    }

    /// Marks the active mission completed, starts its cooldown, and returns the EXP to award.
    @discardableResult
    func completeActiveMission(multiplier: Double = 1.0) -> Int {
        guard var mission = activeMission else { return 0 }
        mission.status = .cooldown
        mission.currentValue = mission.targetValue
        mission.cooldownUntil = Date().addingTimeInterval(
            Constants.missionCooldownHours * 3600)
        update(mission)
        activeMission = nil
        return Int(Double(mission.expReward) * max(multiplier, 1.0))
    }

    /// Moves any cooldown mission whose timer has expired back to available.
    func expireCooldowns() {
        let now = Date()
        var changed = false
        for index in missions.indices {
            guard missions[index].status == .cooldown,
                  let until = missions[index].cooldownUntil,
                  now >= until else { continue }
            missions[index].status = .available
            missions[index].currentValue = 0
            missions[index].cooldownUntil = nil
            changed = true
        }
        if changed { save() }
    }

    func failActiveMission() {
        guard var mission = activeMission else { return }
        mission.status = .failed
        update(mission)
        activeMission = nil
    }

    func cancelActiveMission() {
        guard var mission = activeMission else { return }
        mission.status = .available
        mission.currentValue = 0
        update(mission)
        activeMission = nil
    }

    func resetAll() {
        missions = MockData.missions
        activeMission = nil
        save()
    }

    // MARK: - Persistence (UserDefaults)

    private func update(_ mission: Mission) {
        if let index = missions.firstIndex(where: { $0.id == mission.id }) {
            missions[index] = mission
        }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(missions) else { return }
        defaults.set(data, forKey: Constants.StorageKey.missions)
    }

    private func load() {
        if let data = defaults.data(forKey: Constants.StorageKey.missions),
           let stored = try? JSONDecoder().decode([Mission].self, from: data),
           !stored.isEmpty {
            missions = stored
            activeMission = stored.first { $0.status == .active }
        } else {
            missions = MockData.missions
        }
    }
}
