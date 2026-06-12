import SwiftUI
import MapKit

struct HomeView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var missionViewModel: MissionViewModel
    @EnvironmentObject private var aiViewModel: AIViewModel
    @EnvironmentObject private var locationService: LocationService

    @StateObject private var mapViewModel = MapViewModel()

    @State private var showRoutePreview = false
    @State private var coverMission: Mission?
    @State private var showRouteError = false

    // Live route navigation (after "Start This Route").
    @State private var navigationRoute: RouteResponse?
    @State private var missionAfterNavigation: Mission?

    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: - Map (iOS 14-16 MapKit API)
            Map(coordinateRegion: $locationService.region,
                showsUserLocation: true,
                annotationItems: mapViewModel.pins(missions: missionViewModel.pinnedMissions,
                                                   events: MockData.gameEvents)) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    MissionPinView(pin: pin)
                }
            }
            .ignoresSafeArea(edges: .top)

            // MARK: - Top EXP bar
            VStack {
                HStack(spacing: 10) {
                    if let profile = profileViewModel.profile {
                        CharacterAvatarView(character: profile.character, size: 36)
                        EXPBarView(level: profile.level, currentEXP: profile.currentEXP)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                Spacer()
            }

            // MARK: - Center-on-user button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        locationService.centerOnUser()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.cityAccent)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 6)
                    }
                    .accessibilityLabel("Center map on my location")
                    .padding(.trailing, 16)
                    .padding(.bottom, 190)
                }
            }

            // MARK: - Featured mission card
            if let mission = missionViewModel.featuredMission {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("🎯 \(mission.title)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Text(remainingText(for: mission))
                                .font(.system(size: 12))
                                .foregroundColor(.citySubtext)
                        }
                        Spacer()
                    }

                    HStack(spacing: 10) {
                        Button {
                            generateRoute()
                        } label: {
                            HStack(spacing: 6) {
                                if aiViewModel.isGeneratingRoute {
                                    ProgressView().tint(.cityAccent)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                }
                                Text("Generate Route")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.cityAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.cityAccent.opacity(0.15))
                            .cornerRadius(10)
                        }
                        .disabled(aiViewModel.isGeneratingRoute)

                        Button {
                            start(mission)
                        } label: {
                            Text(mission.status == .active ? "Resume" : "Start")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.cityAccent)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .sheet(isPresented: $showRoutePreview) {
            RoutePreviewView(mapViewModel: mapViewModel,
                             route: aiViewModel.routeResult) { mission in
                showRoutePreview = false
                // Navigate the route first; the mission starts on arrival.
                missionAfterNavigation = mission
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    navigationRoute = aiViewModel.routeResult
                }
            }
        }
        .fullScreenCover(item: $navigationRoute) { route in
            RouteNavigationView(route: route,
                                overlays: mapViewModel.routeOverlays,
                                locationService: locationService) {
                // Arrived — close nav and start the mission.
                navigationRoute = nil
                if let mission = missionAfterNavigation {
                    missionAfterNavigation = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        start(mission)
                    }
                }
            }
            .environmentObject(locationService)
        }
        .fullScreenCover(item: $coverMission) { mission in
            if mission.type == .photo {
                PhotoMissionView(mission: mission)
            } else {
                ActiveMissionView(mission: mission)
            }
        }
        .alert("AI Route Generator", isPresented: $showRouteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(aiViewModel.routeError ?? "Something went wrong.")
        }
    }

    // MARK: - Actions

    private func start(_ mission: Mission) {
        if mission.status != .active {
            missionViewModel.start(mission)
        }
        coverMission = mission
    }

    private func generateRoute() {
        Task {
            let origin = locationService.userLocation ?? locationService.region.center
            await aiViewModel.generateRoute(from: origin,
                                            level: profileViewModel.profile?.level ?? 1,
                                            missions: missionViewModel.pinnedMissions)
            if let route = aiViewModel.routeResult {
                mapViewModel.drawRoute(waypoints: route.waypoints)
                showRoutePreview = true
            } else {
                showRouteError = true
            }
        }
    }

    private func remainingText(for mission: Mission) -> String {
        let remaining = max(mission.targetValue - mission.currentValue, 0)
        switch mission.type {
        case .steps:    return "\(Int(remaining)) steps remaining"
        case .distance: return "\(Int(remaining))m remaining"
        case .photo:    return "Find \(Int(remaining)) more — \(mission.targetObject ?? "object")"
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(ProfileViewModel())
            .environmentObject(MissionViewModel())
            .environmentObject(AIViewModel())
            .environmentObject(LocationService())
    }
}
