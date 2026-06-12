import Foundation

final class MissionViewModel: ObservableObject {
    @Published var missions: [Mission] = []
    @Published var activeMission: Mission?

    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    var availableMissions: [Mission] { missions.filter { $0.status == .available } }
    var completedMissions: [Mission] { missions.filter { $0.status == .completed } }

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
        mission.currentValue = value
        activeMission = mission
        update(mission)
    }

    func incrementPhotoProgress() {
        guard var mission = activeMission, mission.type == .photo else { return }
        mission.currentValue = min(mission.currentValue + 1, mission.targetValue)
        activeMission = mission
        update(mission)
    }

    /// Marks the active mission completed and returns the EXP to award
    /// (base reward × activity multiplier, minimum 1×).
    @discardableResult
    func completeActiveMission(multiplier: Double = 1.0) -> Int {
        guard var mission = activeMission else { return 0 }
        mission.status = .completed
        mission.currentValue = mission.targetValue
        update(mission)
        activeMission = nil
        return Int(Double(mission.expReward) * max(multiplier, 1.0))
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
