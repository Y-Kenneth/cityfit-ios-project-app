import SwiftUI

/// Filters the Missions tab between walking/running missions (steps + distance,
/// which auto-progress during a Home-started walk) and photo-capture missions
/// (picked from the camera icon during a walk).
private enum MissionTypeFilter: String, CaseIterable {
    case walking = "Walk / Run"
    case photo = "Photo"

    func matches(_ type: MissionType) -> Bool {
        switch self {
        case .walking: return type == .steps || type == .distance
        case .photo:   return type == .photo
        }
    }
}

struct MissionsView: View {
    @EnvironmentObject private var missionViewModel: MissionViewModel

    @State private var selectedTab: MissionTypeFilter = .walking
    @State private var selectedMission: Mission?
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cityBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("Mission type", selection: $selectedTab) {
                        ForEach(MissionTypeFilter.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            if let active = missionViewModel.activeMission, selectedTab.matches(active.type) {
                                section("In Progress", missions: [active])
                            }
                            section("Available", missions: filtered(missionViewModel.availableMissions))
                            let cooldowns = filtered(missionViewModel.cooldownMissions)
                            if !cooldowns.isEmpty {
                                cooldownSection(cooldowns)
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Missions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        missionViewModel.resetAll()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .onReceive(timer) { tick in
            now = tick
            missionViewModel.expireCooldowns()
        }
        .sheet(item: $selectedMission) { mission in
            MissionDetailView(mission: mission)
        }
    }

    // MARK: - Filtering

    private func filtered(_ missions: [Mission]) -> [Mission] {
        missions.filter { selectedTab.matches($0.type) }
    }

    // MARK: - Sections

    private func section(_ title: String, missions: [Mission]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.white)
            ForEach(missions) { mission in
                Button {
                    selectedMission = mission
                } label: {
                    MissionCardView(mission: mission)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func cooldownSection(_ missions: [Mission]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("On Cooldown")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.white)
            ForEach(missions) { mission in
                CooldownMissionCardView(mission: mission, now: now)
            }
        }
    }
}

// MARK: - Cooldown card

private struct CooldownMissionCardView: View {
    let mission: Mission
    let now: Date

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.cityPurple.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: mission.type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.cityPurple)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(mission.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))

                if let until = mission.cooldownUntil {
                    let remaining = max(until.timeIntervalSince(now), 0)
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.cityPurple)
                        Text("Resets in \(formatCountdown(remaining))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.cityPurple)
                    }
                }
            }

            Spacer()

            // Cooldown lock icon
            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(.citySubtext)
        }
        .padding(14)
        .background(Color.cityCard.opacity(0.6))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.cityPurple.opacity(0.3), lineWidth: 1)
        )
    }

    private func formatCountdown(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%dh %02dm", h, m)
        }
        return String(format: "%dm %02ds", m, s)
    }
}

struct MissionsView_Previews: PreviewProvider {
    static var previews: some View {
        MissionsView()
            .environmentObject(MissionViewModel())
    }
}
