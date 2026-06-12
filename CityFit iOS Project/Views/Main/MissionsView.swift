import SwiftUI

struct MissionsView: View {
    @EnvironmentObject private var missionViewModel: MissionViewModel

    @State private var selectedMission: Mission?
    @State private var coverMission: Mission?

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
                        if !missionViewModel.completedMissions.isEmpty {
                            section("Completed", missions: missionViewModel.completedMissions)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 80) // keep clear of the floating chat button
                }
            }
            .navigationTitle("Missions")
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
                .disabled(mission.status == .completed)
            }
        }
    }
}

struct MissionsView_Previews: PreviewProvider {
    static var previews: some View {
        MissionsView()
            .environmentObject(MissionViewModel())
    }
}
