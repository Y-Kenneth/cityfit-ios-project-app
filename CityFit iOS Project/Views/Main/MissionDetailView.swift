import SwiftUI

struct MissionDetailView: View {
    let mission: Mission
    /// `nil` presents this as read-only info (no Start/Resume button) — used in
    /// the Missions tab, where missions are now started from Home or the
    /// in-walk photo icon instead of from here.
    var onStart: ((Mission) -> Void)? = nil

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.citySubtext.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.cityAccent.opacity(0.15))
                                .frame(width: 90, height: 90)
                            Image(systemName: mission.type.icon)
                                .font(.system(size: 36))
                                .foregroundColor(.cityAccent)
                        }

                        Text(mission.title)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)

                        Text(mission.description)
                            .font(.system(size: 15))
                            .foregroundColor(.citySubtext)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)

                        HStack(spacing: 12) {
                            statBox(value: "+\(mission.expReward)", label: "EXP", color: .cityYellow)
                            statBox(value: targetLabel, label: "Target", color: .cityAccent)
                            statBox(value: mission.difficulty.label, label: "Difficulty", color: .cityGreen)
                        }
                        .padding(.horizontal, 20)

                        if let limit = mission.timeLimit {
                            Label("Time limit: \(limit) minutes", systemImage: "clock.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.cityYellow)
                        }

                        if mission.type == .photo, let target = mission.targetObject {
                            VStack(spacing: 14) {
                                Label("Point your camera at a \(target)", systemImage: "camera.viewfinder")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.cityAccent)

                                ExamplePhotoGrid(targetObject: target)
                            }
                        }
                    }
                    .padding(.bottom, 12)
                }

                if let onStart {
                    Button {
                        onStart(mission)
                    } label: {
                        Text(mission.status == .active ? "Resume Mission" : "Start Mission")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.cityAccent)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                } else {
                    Spacer().frame(height: 24)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var targetLabel: String {
        "\(Int(mission.targetValue)) \(mission.type.unit)"
    }

    private func statBox(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.citySubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cityCard)
        .cornerRadius(12)
    }
}

struct MissionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MissionDetailView(mission: MockData.missions[0]) { _ in }
    }
}
