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
    @State private var showPlainWalk = false
    @State private var showRouteError = false
    @State private var selectedEvent: GameEvent?
    @State private var showTripError = false
    // Captured at the moment a trip's distance is measured — MapViewModel's
    // own trip state is reset (cancelPlanningTrip) before the result sheet
    // is presented, so TripPreviewView needs its own stable copy.
    @State private var tripPreviewOrigin: CLLocationCoordinate2D?
    @State private var tripPreviewDestination: CLLocationCoordinate2D?
    @State private var tripPreviewPolyline: MKPolyline?

    // Live route navigation (after "Start This Route").
    @State private var navigationRoute: RouteResponse?
    @State private var missionAfterNavigation: Mission?

    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: - Map (3D-tilted UIKit bridge — see HomeMapView)
            HomeMapView(region: $locationService.region,
                       userLocation: locationService.userLocation,
                       pins: mapViewModel.pins(missions: missionViewModel.pinnedMissions,
                                               events: MockData.gameEvents),
                       character: profileViewModel.profile?.character ?? .sportsmanM,
                       heading: locationService.heading,
                       isMoving: locationService.isMoving,
                       isPlanningTrip: mapViewModel.isPlanningTrip,
                       onSelectPin: { pin in
                if let event = MockData.gameEvents.first(where: { "event-\($0.id)" == pin.id }) {
                    selectedEvent = event
                }
            }, onMapTap: mapViewModel.handleTripTap)
            .ignoresSafeArea(edges: .top)

            // MARK: - Top EXP bar + "Plan a Walk" selection banner
            VStack(spacing: 10) {
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

                if mapViewModel.isPlanningTrip {
                    planTripBanner
                        .padding(.horizontal, 16)
                }
                Spacer()
            }

            // MARK: - Center-on-user + Plan-a-Walk buttons
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        if !mapViewModel.isPlanningTrip {
                            Button {
                                mapViewModel.beginPlanningTrip()
                            } label: {
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.cityAccent)
                                    .padding(12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 6)
                            }
                            .accessibilityLabel("Plan a walk between two points")
                        }
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
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 190)
                }
            }

            // MARK: - Featured mission card
            if let mission = missionViewModel.featuredMission {
                featuredMissionCard(mission)
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
        .fullScreenCover(isPresented: $showPlainWalk) {
            ActiveMissionView(mission: nil)
        }
        .alert("AI Route Generator", isPresented: $showRouteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(aiViewModel.routeError ?? "Something went wrong.")
        }
        .sheet(item: $selectedEvent) { event in
            GameEventDetailView(event: event)
        }
        .onChange(of: mapViewModel.tripDistanceMeters) { distance in
            guard let distance,
                  let origin = mapViewModel.tripOrigin,
                  let destination = mapViewModel.tripDestination else { return }
            let polyline = mapViewModel.tripPolyline
            Task {
                await aiViewModel.planTrip(origin: origin, destination: destination,
                                           distanceMeters: distance,
                                           level: profileViewModel.profile?.level ?? 1,
                                           weightKg: profileViewModel.profile?.weightKg ?? 70)
                if aiViewModel.tripResult != nil {
                    tripPreviewOrigin = origin
                    tripPreviewDestination = destination
                    tripPreviewPolyline = polyline
                } else {
                    showTripError = true
                }
                mapViewModel.cancelPlanningTrip()
            }
        }
        .sheet(item: $aiViewModel.tripResult) { trip in
            TripPreviewView(trip: trip,
                            origin: tripPreviewOrigin ?? locationService.region.center,
                            destination: tripPreviewDestination ?? locationService.region.center,
                            polyline: tripPreviewPolyline)
        }
        .alert("AI Trip Planner", isPresented: $showTripError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(aiViewModel.tripError ?? "Something went wrong.")
        }
    }

    // MARK: - "Plan a Walk" banner

    private var planTripBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
                .foregroundColor(.cityAccent)
            Text(tripBannerText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            if aiViewModel.isPlanningTripRequest {
                ProgressView().tint(.white)
            }
            Button("Cancel") {
                mapViewModel.cancelPlanningTrip()
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.citySubtext)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private var tripBannerText: String {
        if aiViewModel.isPlanningTripRequest {
            return "Calculating your trip…"
        } else if mapViewModel.tripOrigin == nil {
            return "Tap your starting point"
        } else {
            return "Tap your destination"
        }
    }

    // MARK: - Featured mission card

    private func featuredMissionCard(_ mission: Mission) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("FEATURED MISSION")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(.citySubtext)
                    Text(mission.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: mission.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.citySubtext)
            }

            if mission.type != .photo {
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1)).frame(height: 3)
                            Capsule().fill(Color.cityAccent)
                                .frame(width: geo.size.width * CGFloat(mission.progress), height: 3)
                        }
                    }
                    .frame(height: 3)
                    Text(remainingText(for: mission))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.citySubtext)
                }
            } else {
                Text(remainingText(for: mission))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.citySubtext)
            }

            HStack(spacing: 10) {
                Button {
                    generateRoute()
                } label: {
                    HStack(spacing: 6) {
                        if aiViewModel.isGeneratingRoute {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Text("Generate Route")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
                }
                .disabled(aiViewModel.isGeneratingRoute)

                Button {
                    showPlainWalk = true
                } label: {
                    Text("Start")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.cityAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
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
            let landmarkPins = await LandmarkSearchService.shared.nearbyLandmarkPins(around: origin)
            await aiViewModel.generateRoute(from: origin,
                                            level: profileViewModel.profile?.level ?? 1,
                                            missions: missionViewModel.pinnedMissions,
                                            landmarkPins: landmarkPins)
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
