import SwiftUI
import MapKit

/// Live, map-based tracking for active step + distance missions (Pokémon-GO
/// style): the user's location moves on the map in real time, with a compact
/// progress overlay. Real pedometer/GPS on device; a mock walk drives both on
/// the Simulator.
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

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(mission: Mission) {
        self.mission = mission
        _tracker = StateObject(wrappedValue: MissionTracker(mission: mission))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Live map fills the screen — the user's dot moves as they walk.
            MissionMapView(userLocation: tracker.userLocation,
                           trail: tracker.trail,
                           destination: mission.coordinate)
                .ignoresSafeArea()

            topBar
            progressPanel

            if failed {
                failedOverlay
            }

            if let exp = completionEXP {
                MissionCompleteView(expAwarded: exp, leveledUp: leveledUp) {
                    dismiss()
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
        .onReceive(timer) { _ in
            tick()
        }
        .confirmationDialog("Give up this mission?", isPresented: $showGiveUpConfirm, titleVisibility: .visible) {
            Button("Give Up", role: .destructive) {
                missionViewModel.cancelActiveMission()
                dismiss()
            }
            Button("Keep Going", role: .cancel) {}
        }
    }

    // MARK: - Overlays

    private var topBar: some View {
        VStack {
            HStack {
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
                Text(timeText)
                    .font(.system(size: 15, weight: .bold).monospacedDigit())
                    .foregroundColor(mission.timeLimit != nil ? .cityYellow : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.cityCard.opacity(0.9))
                    .cornerRadius(20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            Spacer()
        }
    }

    private var progressPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(mission.title)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.white)

            // Progress bar (replaces the ring; map is now the focus).
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

    // MARK: - Live values

    private var distanceValue: Double {
        // GPS distance on device; the pedometer mock feeds distance on the Simulator
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

struct ActiveMissionView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveMissionView(mission: MockData.missions[0])
            .environmentObject(MissionViewModel())
            .environmentObject(ProfileViewModel())
            .environmentObject(LocationService())
    }
}
