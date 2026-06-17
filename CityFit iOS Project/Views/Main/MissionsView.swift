import SwiftUI

struct MissionsView: View {
    @EnvironmentObject private var missionViewModel: MissionViewModel

    @State private var selectedMission: Mission?
    @State private var coverMission: Mission?
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cityBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if let active = missionViewModel.activeMission {
                            section("In Progress", missions: [active])
                        }
                        section("Available", missions: missionViewModel.availableMissions)
                        if !missionViewModel.cooldownMissions.isEmpty {
                            cooldownSection
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 80)
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
            MissionDetailView(mission: mission) { started in
                selectedMission = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    missionViewModel.start(started)
                    coverMission = started
                }
            }
        }
        .fullScreenCover(item: $coverMission) { mission in
            if mission.type == .photo {
                PhotoMissionView(mission: mission)
            } else {
                ActiveMissionView(mission: mission)
            }
        }
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

    private var cooldownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("On Cooldown")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.white)
            ForEach(missionViewModel.cooldownMissions) { mission in
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
