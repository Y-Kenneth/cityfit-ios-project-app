import SwiftUI
import MapKit

/// AI-generated route summary shown after the Route Crew responds:
/// MKMapView polyline preview + metrics card + "Start This Route".
struct RoutePreviewView: View {
    @ObservedObject var mapViewModel: MapViewModel
    let route: RouteResponse?
    let onStartMission: (Mission) -> Void

    @EnvironmentObject private var missionViewModel: MissionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            RouteMapView(overlays: mapViewModel.routeOverlays,
                         waypoints: mapViewModel.routeWaypoints)
                .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: 12) {
                Label("AI Generated Route", systemImage: "wand.and.stars")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.cityAccent)

                if let route {
                    Text(metricsLine(for: route))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text(route.summary)
                        .font(.system(size: 13))
                        .foregroundColor(.citySubtext)
                        .lineLimit(3)

                    // Waypoint order
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(route.waypoints.enumerated()), id: \.offset) { index, waypoint in
                            Text("\(index + 1). \(waypoint.title)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.citySubtext)
                        }
                    }

                    Button {
                        startRoute(route)
                    } label: {
                        Text("Start This Route")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.cityAccent)
                            .cornerRadius(14)
                    }
                } else {
                    Text("No route available.")
                        .foregroundColor(.citySubtext)
                }
            }
            .padding(20)
            .background(Color.cityBackground)
        }
        .background(Color.cityBackground)
    }

    private func metricsLine(for route: RouteResponse) -> String {
        let km = routeDistanceKm(route)
        return String(format: "%.1fkm · %dmin · %d EXP · ~%d cal",
                      km, route.minutes, route.exp, route.calories)
    }

    private func routeDistanceKm(_ route: RouteResponse) -> Double {
        let coordinates = route.waypoints.map(\.coordinate)
        guard coordinates.count >= 2 else { return 0 }
        var meters = 0.0
        for index in 0..<(coordinates.count - 1) {
            let a = CLLocation(latitude: coordinates[index].latitude,
                               longitude: coordinates[index].longitude)
            let b = CLLocation(latitude: coordinates[index + 1].latitude,
                               longitude: coordinates[index + 1].longitude)
            meters += b.distance(from: a)
        }
        return meters / 1000
    }

    /// Missions on the route activate in waypoint order — start the first one.
    private func startRoute(_ route: RouteResponse) {
        let titles = route.waypoints.map(\.title)
        let first = missionViewModel.missions.first { mission in
            mission.status == .available && titles.contains(mission.title)
        }
        if let first {
            onStartMission(first)
        } else {
            dismiss()
        }
    }
}
