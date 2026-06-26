import SwiftUI
import MapKit

/// Live navigation for an AI-generated route: full-screen map with the route
/// polyline, the user's moving location, and a panel showing distance to the
/// next waypoint and total distance left. On arrival it hands off to the
/// normal mission flow (which awards EXP).
///
/// Scope: route path + live distance readouts. No voice/turn-by-turn or
/// off-route rerouting (iOS 16 SDK constraint — see CLAUDE.md).
struct RouteNavigationView: View {
    let route: RouteResponse
    let overlays: [MKPolyline]
    /// Called when the user reaches the final waypoint — starts the mission.
    let onArrive: () -> Void

    @EnvironmentObject private var locationService: LocationService
    @StateObject private var viewModel: RouteNavigationViewModel
    @Environment(\.dismiss) private var dismiss

    init(route: RouteResponse,
         overlays: [MKPolyline],
         locationService: LocationService,
         onArrive: @escaping () -> Void) {
        self.route = route
        self.overlays = overlays
        self.onArrive = onArrive
        _viewModel = StateObject(wrappedValue: RouteNavigationViewModel(
            waypoints: route.waypoints, locationService: locationService))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationMapView(overlays: overlays,
                              waypoints: route.waypoints,
                              userLocation: viewModel.userLocation,
                              nextWaypointIndex: viewModel.nextWaypointIndex)
                .ignoresSafeArea()

            closeButton
            navPanel
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .onChange(of: viewModel.arrived) { arrived in
            guard arrived else { return }
            onArrive()
        }
    }

    // MARK: - Overlay controls

    private var closeButton: some View {
        VStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.game(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.cityCard.opacity(0.9))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Stop navigation")
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            Spacer()
        }
    }

    private var navPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Navigating route", systemImage: "location.north.line.fill")
                .font(.game(size: 13, weight: .bold))
                .foregroundColor(.cityAccent)

            // Primary: distance to the next waypoint.
            VStack(alignment: .leading, spacing: 2) {
                Text(distanceString(viewModel.distanceToNext))
                    .font(.game(size: 40, weight: .heavy).monospacedDigit())
                    .foregroundColor(.white)
                Text("to \(viewModel.nextWaypointTitle)")
                    .font(.game(size: 15, weight: .medium))
                    .foregroundColor(.citySubtext)
            }

            Divider().background(Color.citySubtext.opacity(0.3))

            // Secondary: total distance left + waypoint progress.
            HStack {
                metric(title: "Total left", value: distanceString(viewModel.distanceRemaining))
                Spacer()
                metric(title: "Waypoint",
                       value: "\(min(viewModel.nextWaypointIndex + 1, viewModel.totalWaypoints))/\(viewModel.totalWaypoints)")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cityBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.game(size: 11))
                .foregroundColor(.citySubtext)
            Text(value)
                .font(.game(size: 18, weight: .bold).monospacedDigit())
                .foregroundColor(.white)
        }
    }

    /// Meters under 1 km, otherwise km with one decimal.
    private func distanceString(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }
}

struct RouteNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        RouteNavigationView(
            route: RouteResponse(
                waypoints: [
                    .init(lat: 32.0620, lng: 118.7980, title: "Morning Sprinter"),
                    .init(lat: 32.0590, lng: 118.7950, title: "City Explorer")
                ],
                calories: 24, exp: 350, minutes: 5,
                summary: "A quick city stroll."),
            overlays: [],
            locationService: LocationService(),
            onArrive: {})
        .environmentObject(LocationService())
    }
}
