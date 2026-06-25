import SwiftUI
import MapKit

struct ActiveMissionView: View {
    /// The specific mission this walk targets, e.g. via the AI-route arrival flow.
    /// `nil` for a plain walk/run session started from Home, where every eligible
    /// steps/distance mission progresses passively instead of one "primary" mission.
    let mission: Mission?

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
    @State private var showPhotoMissionPicker = false
    @State private var capturePhotoMission: Mission?
    @State private var passiveBonusEXP: Int?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(mission: Mission?) {
        self.mission = mission
        _tracker = StateObject(wrappedValue: MissionTracker(mission: mission))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            MissionMapView(userLocation: tracker.userLocation,
                           trail: tracker.trail,
                           destination: mission?.coordinate)
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
                if mission != nil { missionViewModel.cancelActiveMission() }
                dismiss()
            }
            Button("Keep Going", role: .cancel) {}
        }
        .sheet(isPresented: $showMissionsTray) {
            MissionsTrayView(steps: pedometer.stepCount, distance: distanceValue)
        }
        .sheet(isPresented: $showPhotoMissionPicker) {
            PhotoMissionPickerView { picked in
                showPhotoMissionPicker = false
                missionViewModel.start(picked)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    capturePhotoMission = picked
                }
            }
        }
        .fullScreenCover(item: $capturePhotoMission) { photoMission in
            PhotoMissionView(mission: photoMission)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack {
            HStack(spacing: 10) {
                Spacer()

                // Photo missions: pick one, jump straight into the camera
                Button {
                    showPhotoMissionPicker = true
                } label: {
                    badgedIcon(systemName: "camera.fill",
                               count: missionViewModel.availablePhotoMissions.count)
                }
                .accessibilityLabel("Find a photo mission to capture")

                // Missions tray
                Button {
                    showMissionsTray = true
                } label: {
                    badgedIcon(systemName: "list.bullet",
                               count: missionViewModel.passiveWalkingMissions.count)
                }
                .accessibilityLabel("View all missions")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            Spacer()
        }
    }

    private func badgedIcon(systemName: String, count: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))

            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(Color.cityAccent, in: Circle())
                    .offset(x: 3, y: -3)
            }
        }
    }

    // MARK: - Progress panel

    private var progressPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Image(systemName: activityIcon)
                        .font(.system(size: 13, weight: .semibold))
                    Text(activityService.activity.label.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundColor(.citySubtext)
                Spacer()
                if activityService.expMultiplier > 1 {
                    Text("\(activityService.expMultiplier, specifier: "%.0f")× EXP")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cityAccent)
                }
            }

            if let mission {
                Text(mission.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1)).frame(height: 3)
                            Capsule().fill(Color.cityAccent)
                                .frame(width: geo.size.width * CGFloat(min(progressValue / mission.targetValue, 1)),
                                       height: 3)
                                .animation(.easeOut(duration: 0.4), value: progressValue)
                        }
                    }
                    .frame(height: 3)
                    Text("\(Int(progressValue)) / \(Int(mission.targetValue)) \(mission.type.unit) · +\(mission.expReward) EXP")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.citySubtext)
                }
            }

            HStack(alignment: .bottom, spacing: 0) {
                statColumn(value: "\(pedometer.stepCount)", label: "Steps")
                Divider().background(Color.white.opacity(0.12)).frame(height: 38)
                    .padding(.horizontal, 18)
                statColumn(value: String(format: "%.0f", distanceValue), label: "Meters")
                Divider().background(Color.white.opacity(0.12)).frame(height: 38)
                    .padding(.horizontal, 18)
                statColumn(value: timeText, label: "Time", isMonospaced: true)
                Spacer(minLength: 0)
            }

            Button {
                showGiveUpConfirm = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("End Walk")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
            .accessibilityLabel("Give up mission")
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Computed values

    private var distanceValue: Double {
        max(locationService.trackedDistance, pedometer.distance)
    }

    /// Progress toward the primary mission's target, if there is one. A plain
    /// walk session (`mission == nil`) has no single target to track here —
    /// completion for every eligible mission instead happens via the passive
    /// progress update in `tick()`.
    private var progressValue: Double {
        guard let mission else { return 0 }
        switch mission.type {
        case .steps:    return Double(pedometer.stepCount)
        case .distance: return distanceValue
        case .photo:    return mission.currentValue
        }
    }

    private var timeText: String {
        if let limit = mission?.timeLimit {
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

        // A plain walk session has no single primary mission to complete or
        // time out on — every eligible mission already completes passively above.
        guard let mission else { return }
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

    private func statColumn(value: String, label: String, isMonospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(isMonospaced
                      ? .system(size: 26, weight: .bold).monospacedDigit()
                      : .system(size: 26, weight: .bold))
                .foregroundColor(.white)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(.citySubtext)
        }
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

// MARK: - Photo mission picker sheet

/// Lets the user pick a photo-capture mission while walking — spot a bottle or
/// a cat, check the list, tap the matching mission, and the camera opens
/// straight into capture mode for that object.
private struct PhotoMissionPickerView: View {
    @EnvironmentObject private var missionViewModel: MissionViewModel
    let onPick: (Mission) -> Void

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.cityYellow)
                    Text("Photo Missions")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(20)

                Text("See one of these nearby? Tap it to open the camera.")
                    .font(.system(size: 13))
                    .foregroundColor(.citySubtext)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                Divider().background(Color.cityCard)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(missionViewModel.availablePhotoMissions) { mission in
                            Button {
                                onPick(mission)
                            } label: {
                                MissionCardView(mission: mission)
                            }
                            .buttonStyle(.plain)
                        }
                        if missionViewModel.availablePhotoMissions.isEmpty {
                            Text("No photo missions available right now.")
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
