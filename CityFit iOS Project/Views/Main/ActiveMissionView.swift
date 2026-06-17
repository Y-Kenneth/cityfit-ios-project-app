import SwiftUI
import MapKit

struct ActiveMissionView: View {
    let mission: Mission

    @EnvironmentObject private var missionViewModel: MissionViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var locationService: LocationService
    @StateObject private var pedometer = PedometerService()
    @StateObject private var activityService = ActivityService()
    @StateObject private var tracker: MissionTracker
    @Environment(\.dismiss) private var dismiss

    @State private var elapsedSeconds = 0
    @State private var completionEXP: Int?
    @State private var leveledUp = false
    @State private var failed = false
    @State private var showGiveUpConfirm = false
    @State private var showMissionsTray = false
    @State private var passiveBonusEXP: Int?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(mission: Mission) {
        self.mission = mission
        _tracker = StateObject(wrappedValue: MissionTracker(mission: mission))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            MissionMapView(userLocation: tracker.userLocation,
                           trail: tracker.trail,
                           destination: mission.coordinate)
                .ignoresSafeArea()

            topBar
            progressPanel

            if failed { failedOverlay }

            if let exp = completionEXP {
                MissionCompleteView(expAwarded: exp, leveledUp: leveledUp) {
                    dismiss()
                }
            }

            // Passive bonus toast
            if let bonus = passiveBonusEXP {
                VStack {
                    Spacer()
                    Text("+\(bonus) EXP — Bonus mission complete!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.cityGreen)
                        .cornerRadius(20)
                        .shadow(color: .cityGreen.opacity(0.4), radius: 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.bottom, 260)
                }
            }
        }
        .onAppear {
            pedometer.startTracking()
            activityService.start()
            locationService.startDistanceTracking()
            tracker.start(locationService: locationService)
        }
        .onDisappear {
            pedometer.stopTracking()
            activityService.stop()
            locationService.stopDistanceTracking()
            tracker.stop()
        }
        .onReceive(timer) { _ in tick() }
        .confirmationDialog("Give up this mission?", isPresented: $showGiveUpConfirm, titleVisibility: .visible) {
            Button("Give Up", role: .destructive) {
                missionViewModel.cancelActiveMission()
                dismiss()
            }
            Button("Keep Going", role: .cancel) {}
        }
        .sheet(isPresented: $showMissionsTray) {
            MissionsTrayView(steps: pedometer.stepCount, distance: distanceValue)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack {
            HStack {
                // Quit
                Button {
                    showGiveUpConfirm = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.cityCard.opacity(0.9))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Give up mission")

                Spacer()

                // Timer
                Text(timeText)
                    .font(.system(size: 15, weight: .bold).monospacedDigit())
                    .foregroundColor(mission.timeLimit != nil ? .cityYellow : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.cityCard.opacity(0.9))
                    .cornerRadius(20)

                Spacer()

                // Missions tray
                Button {
                    showMissionsTray = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "list.bullet.clipboard.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.cityAccent.opacity(0.9))
                            .clipShape(Circle())

                        // Badge: count of passive missions in progress
                        let passiveCount = missionViewModel.passiveWalkingMissions.count
                        if passiveCount > 0 {
                            Text("\(passiveCount)")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.black)
                                .padding(4)
                                .background(Color.cityGreen)
                                .clipShape(Circle())
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                .accessibilityLabel("View all missions")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            Spacer()
        }
    }

    // MARK: - Progress panel

    private var progressPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(mission.title)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.cityCard)
                        Capsule().fill(Color.cityGreen)
                            .frame(width: geo.size.width * CGFloat(min(progressValue / mission.targetValue, 1)))
                            .animation(.easeOut(duration: 0.4), value: progressValue)
                    }
                }
                .frame(height: 12)
                Text("\(Int(progressValue)) of \(Int(mission.targetValue)) \(mission.type.unit)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.citySubtext)
            }

            HStack(spacing: 8) {
                Image(systemName: activityIcon)
                Text(activityService.activity.label)
                Text("×\(activityService.expMultiplier, specifier: "%.0f") EXP")
                    .foregroundColor(.cityYellow)
                Spacer()
                Text("+\(mission.expReward)")
                    .foregroundColor(.cityGreen)
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)

            HStack(spacing: 12) {
                statBox(value: "\(pedometer.stepCount)", label: "Steps")
                statBox(value: String(format: "%.0fm", distanceValue), label: "Distance")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cityBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Computed values

    private var distanceValue: Double {
        max(locationService.trackedDistance, pedometer.distance)
    }

    private var progressValue: Double {
        switch mission.type {
        case .steps:    return Double(pedometer.stepCount)
        case .distance: return distanceValue
        case .photo:    return mission.currentValue
        }
    }

    private var timeText: String {
        if let limit = mission.timeLimit {
            let remaining = max(limit * 60 - elapsedSeconds, 0)
            return String(format: "⏱ %d:%02d left", remaining / 60, remaining % 60)
        }
        return String(format: "%d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }

    private var activityIcon: String {
        switch activityService.activity {
        case .walking:    return "figure.walk"
        case .running:    return "figure.run"
        case .stationary: return "figure.stand"
        }
    }

    // MARK: - Tick / completion

    private func tick() {
        guard completionEXP == nil, !failed else { return }
        elapsedSeconds += 1
        missionViewModel.updateActiveProgress(progressValue)

        // Passive missions: update all available walking/distance missions
        let bonuses = missionViewModel.updatePassiveProgress(
            steps: pedometer.stepCount,
            distance: distanceValue,
            multiplier: activityService.expMultiplier)

        if !bonuses.isEmpty {
            let totalBonus = bonuses.reduce(0) { $0 + $1.1 }
            bonuses.forEach { profileViewModel.addEXP($0.1) }
            withAnimation { passiveBonusEXP = totalBonus }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { passiveBonusEXP = nil }
            }
        }

        if progressValue >= mission.targetValue {
            complete()
        } else if let limit = mission.timeLimit, elapsedSeconds >= limit * 60 {
            fail()
        }
    }

    private func complete() {
        pedometer.stopTracking()
        activityService.stop()
        locationService.stopDistanceTracking()
        tracker.stop()
        let exp = missionViewModel.completeActiveMission(multiplier: activityService.expMultiplier)
        profileViewModel.addEXP(exp)
        leveledUp = profileViewModel.justLeveledUp
        profileViewModel.recordMissionCompletion(steps: pedometer.stepCount)
        withAnimation { completionEXP = exp }
    }

    private func fail() {
        missionViewModel.failActiveMission()
        withAnimation { failed = true }
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .heavy).monospacedDigit())
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.citySubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.cityCard)
        .cornerRadius(12)
    }

    private var failedOverlay: some View {
        VStack(spacing: 16) {
            Text("⏰")
                .font(.system(size: 60))
            Text("Time's up!")
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(.white)
            Text("Don't worry — the mission is back on the board.")
                .font(.system(size: 14))
                .foregroundColor(.citySubtext)
            Button {
                dismiss()
            } label: {
                Text("Back to Map")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color.cityAccent)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cityBackground.opacity(0.95))
        .ignoresSafeArea()
    }
}

// MARK: - Missions tray sheet

private struct MissionsTrayView: View {
    @EnvironmentObject private var missionViewModel: MissionViewModel
    let steps: Int
    let distance: Double

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.cityAccent)
                    Text("Active Walking Missions")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(20)

                Text("These missions progress automatically while you walk.")
                    .font(.system(size: 13))
                    .foregroundColor(.citySubtext)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                Divider().background(Color.cityCard)

                ScrollView {
                    VStack(spacing: 12) {
                        // The primary active mission
                        if let active = missionViewModel.activeMission {
                            trayRow(mission: active, steps: steps, distance: distance, isPrimary: true)
                        }
                        // All passive walking missions
                        ForEach(missionViewModel.passiveWalkingMissions) { mission in
                            trayRow(mission: mission, steps: steps, distance: distance, isPrimary: false)
                        }
                        if missionViewModel.passiveWalkingMissions.isEmpty &&
                           missionViewModel.activeMission == nil {
                            Text("No walking missions available.")
                                .font(.system(size: 14))
                                .foregroundColor(.citySubtext)
                                .padding(24)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private func trayRow(mission: Mission, steps: Int, distance: Double, isPrimary: Bool) -> some View {
        let current: Double = mission.type == .steps ? Double(steps) : distance
        let progress = min(current / mission.targetValue, 1.0)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: mission.type.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isPrimary ? .cityAccent : .cityGreen)
                Text(mission.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                if isPrimary {
                    Text("Primary")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.cityAccent)
                        .cornerRadius(6)
                }
                Text("+\(mission.expReward) EXP")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.cityYellow)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.cityCard)
                    Capsule()
                        .fill(isPrimary ? Color.cityAccent : Color.cityGreen)
                        .frame(width: geo.size.width * CGFloat(progress))
                        .animation(.easeOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 8)

            Text("\(Int(min(current, mission.targetValue))) / \(Int(mission.targetValue)) \(mission.type.unit)")
                .font(.system(size: 12))
                .foregroundColor(.citySubtext)
        }
        .padding(14)
        .background(Color.cityCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isPrimary ? Color.cityAccent.opacity(0.4) : Color.cityGreen.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ActiveMissionView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveMissionView(mission: MockData.missions[0])
            .environmentObject(MissionViewModel())
            .environmentObject(ProfileViewModel())
            .environmentObject(LocationService())
    }
}
