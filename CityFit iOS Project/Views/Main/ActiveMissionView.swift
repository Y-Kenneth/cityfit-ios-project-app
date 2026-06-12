import SwiftUI

/// Live tracking screen for step + distance missions:
/// real pedometer/GPS on device, mock timer on the Simulator.
struct ActiveMissionView: View {
    let mission: Mission

    @EnvironmentObject private var missionViewModel: MissionViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var locationService: LocationService
    @StateObject private var pedometer = PedometerService()
    @StateObject private var activityService = ActivityService()
    @Environment(\.dismiss) private var dismiss

    @State private var elapsedSeconds = 0
    @State private var completionEXP: Int?
    @State private var leveledUp = false
    @State private var failed = false
    @State private var showGiveUpConfirm = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Button {
                        showGiveUpConfirm = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.citySubtext)
                            .padding(10)
                            .background(Color.cityCard)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Give up mission")
                    Spacer()
                    Text(timeText)
                        .font(.system(size: 15, weight: .bold).monospacedDigit())
                        .foregroundColor(mission.timeLimit != nil ? .cityYellow : .citySubtext)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Text(mission.title)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.cityCard, lineWidth: 16)
                    Circle()
                        .trim(from: 0, to: CGFloat(min(progressValue / mission.targetValue, 1)))
                        .stroke(Color.cityGreen,
                                style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.4), value: progressValue)
                    VStack(spacing: 4) {
                        Text("\(Int(progressValue))")
                            .font(.system(size: 44, weight: .heavy).monospacedDigit())
                            .foregroundColor(.white)
                        Text("of \(Int(mission.targetValue)) \(mission.type.unit)")
                            .font(.system(size: 14))
                            .foregroundColor(.citySubtext)
                    }
                }
                .frame(width: 220, height: 220)
                .padding(.vertical, 10)

                // Activity + multiplier badge (CoreML / heuristic)
                HStack(spacing: 8) {
                    Image(systemName: activityIcon)
                    Text(activityService.activity.label)
                    Text("×\(activityService.expMultiplier, specifier: "%.0f") EXP")
                        .foregroundColor(.cityYellow)
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.cityCard)
                .cornerRadius(12)

                // Live stats
                HStack(spacing: 12) {
                    statBox(value: "\(pedometer.stepCount)", label: "Steps")
                    statBox(value: String(format: "%.0fm", distanceValue), label: "Distance")
                    statBox(value: "+\(mission.expReward)", label: "Reward")
                }
                .padding(.horizontal, 20)

                Spacer()
            }

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
        }
        .onDisappear {
            pedometer.stopTracking()
            activityService.stop()
            locationService.stopDistanceTracking()
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
