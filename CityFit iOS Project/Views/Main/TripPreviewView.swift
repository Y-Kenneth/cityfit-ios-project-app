import SwiftUI
import MapKit

/// AI-calculated walk/run estimate for a point-to-point trip the user picked
/// on the Home map: MKMapView polyline preview (reuses RouteMapView, the
/// same UIKit bridge the AI-generated-route flow already uses) + distance +
/// side-by-side walk/run metric cards from the Trip Crew's Pace Estimator.
struct TripPreviewView: View {
    let trip: TripResponse
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let polyline: MKPolyline?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                RouteMapView(overlays: polyline.map { [$0] } ?? [], waypoints: waypoints)
                    .frame(height: geo.size.height * 0.42)
                    .ignoresSafeArea(edges: .top)

                // Scrollable so the AI's explanation paragraph is never cropped,
                // however long it runs.
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("AI Trip Planner", systemImage: "figure.walk")
                            .font(.game(size: 16, weight: .heavy))
                            .foregroundColor(.cityAccent)

                        Text(String(format: "%.1fkm", trip.distance_meters / 1000))
                            .font(.game(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text(trip.summary)
                            .font(.game(size: 13))
                            .foregroundColor(.citySubtext)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 12) {
                            modeCard(icon: "figure.walk", title: "Walk", estimate: trip.walk)
                            modeCard(icon: "figure.run", title: "Run", estimate: trip.run)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Done stays pinned below the scroll area so it's always reachable.
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.game(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.cityAccent)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(Color.cityBackground)
        }
        .background(Color.cityBackground)
    }

    private var waypoints: [RouteResponse.Waypoint] {
        [RouteResponse.Waypoint(lat: origin.latitude, lng: origin.longitude, title: "Start"),
         RouteResponse.Waypoint(lat: destination.latitude, lng: destination.longitude, title: "Finish")]
    }

    private func modeCard(icon: String, title: String, estimate: TripResponse.ModeEstimate) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.game(size: 13, weight: .bold))
                .foregroundColor(.cityAccent)
            Text("\(estimate.steps) steps")
                .font(.game(size: 13, weight: .semibold))
                .foregroundColor(.white)
            Text("\(estimate.minutes) min · ~\(estimate.calories) cal")
                .font(.game(size: 12))
                .foregroundColor(.citySubtext)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cityCard)
        .cornerRadius(12)
    }
}

struct TripPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        TripPreviewView(
            trip: TripResponse(distance_meters: 650,
                               walk: .init(steps: 850, minutes: 8, calories: 35),
                               run: .init(steps: 600, minutes: 4, calories: 60),
                               summary: "A nice easy stroll to get your steps in!"),
            origin: CLLocationCoordinate2D(latitude: 32.0603, longitude: 118.7964),
            destination: CLLocationCoordinate2D(latitude: 32.0650, longitude: 118.8010),
            polyline: nil)
    }
}
