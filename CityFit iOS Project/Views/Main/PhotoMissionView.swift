import SwiftUI

/// Camera screen for photo missions using the two-tier detection system:
/// Apple Vision live (Tier 1) + Groq Vision "Snap" confirmation (Tier 2).
struct PhotoMissionView: View {
    let mission: Mission

    @EnvironmentObject private var missionViewModel: MissionViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var aiViewModel: AIViewModel
    @StateObject private var cameraViewModel = CameraViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var completionEXP: Int?
    @State private var leveledUp = false

    private var currentCount: Int {
        Int(missionViewModel.activeMission?.currentValue ?? mission.currentValue)
    }

    private var targetCount: Int { Int(mission.targetValue) }
    private var target: String { mission.targetObject ?? "object" }

    var body: some View {
        ZStack {
            // Camera feed (placeholder on Simulator)
            if cameraViewModel.camera.isAvailable {
                CameraPreviewView(session: cameraViewModel.camera.session)
                    .ignoresSafeArea()
            } else {
                simulatorPlaceholder
            }

            VStack {
                // Top bar: target + progress
                HStack {
                    Button {
                        missionViewModel.cancelActiveMission()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Cancel photo mission")

                    Spacer()

                    Text("🎯 \(mission.title)  \(currentCount)/\(targetCount)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                }
                .padding(16)

                Spacer()

                // Detection banner + actions
                VStack(spacing: 14) {
                    DetectionBannerView(state: cameraViewModel.state,
                                        message: cameraViewModel.statusMessage ?? defaultHint)

                    if cameraViewModel.state == .possible {
                        Button {
                            Task {
                                await cameraViewModel.snap(
                                    userID: profileViewModel.profile?.id ?? "anonymous",
                                    aiViewModel: aiViewModel)
                            }
                        } label: {
                            Label("Snap", systemImage: "camera.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(Color.cityYellow)
                                .cornerRadius(14)
                        }
                    }

                    if cameraViewModel.state == .verifying {
                        ProgressView()
                            .tint(.cityAccent)
                    }
                }
                .padding(.bottom, 50)
            }

            if let exp = completionEXP {
                MissionCompleteView(expAwarded: exp, leveledUp: leveledUp) {
                    dismiss()
                }
            }
        }
        .onAppear {
            cameraViewModel.onObjectFound = { objectFound() }
            cameraViewModel.start(target: target)
        }
        .onDisappear {
            cameraViewModel.stop()
        }
    }

    private var defaultHint: String? {
        "Point camera at a \(target)"
    }

    private func objectFound() {
        missionViewModel.incrementPhotoProgress()
        if let active = missionViewModel.activeMission, active.isComplete {
            let exp = missionViewModel.completeActiveMission()
            profileViewModel.addEXP(exp)
            leveledUp = profileViewModel.justLeveledUp
            profileViewModel.recordMissionCompletion(steps: 0)
            withAnimation { completionEXP = exp }
        }
    }

    /// The Simulator has no camera — drive the same detection state machine
    /// with demo buttons so the flow can still be tested end to end.
    private var simulatorPlaceholder: some View {
        ZStack {
            LinearGradient(colors: [.cityBackground, .cityCard],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.citySubtext)
                Text("Camera unavailable on Simulator")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.citySubtext)

                Button("Simulate clear detection") {
                    cameraViewModel.simulateDetection(confidence: 0.92)
                }
                Button("Simulate uncertain detection") {
                    cameraViewModel.simulateDetection(confidence: 0.62)
                }
            }
            .buttonStyle(.bordered)
            .tint(.cityAccent)
        }
    }
}

struct PhotoMissionView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoMissionView(mission: MockData.missions[6])
            .environmentObject(MissionViewModel())
            .environmentObject(ProfileViewModel())
            .environmentObject(AIViewModel())
    }
}
