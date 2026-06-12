import SwiftUI
import MapKit

/// Live navigation map (UIKit bridge — iOS 16 SwiftUI Map cannot draw polyline
/// overlays). Shows the route polyline, numbered waypoint pins, the user's
/// location, and re-centers on the user as they move.
struct NavigationMapView: UIViewRepresentable {
    let overlays: [MKPolyline]
    let waypoints: [RouteResponse.Waypoint]
    /// The user's current position (real GPS on device, mocked on Simulator).
    let userLocation: CLLocationCoordinate2D?
    /// Index of the next waypoint the user is heading to.
    let nextWaypointIndex: Int

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Refresh overlays + pins (cheap; counts stay small).
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(overlays)

        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        for (index, waypoint) in waypoints.enumerated() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = waypoint.coordinate
            annotation.title = "\(index + 1). \(waypoint.title)"
            mapView.addAnnotation(annotation)
        }

        // Follow the user once we have a fix, keeping a navigation-style zoom.
        if let userLocation {
            let span = MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
            let region = MKCoordinateRegion(center: userLocation, span: span)
            mapView.setRegion(region, animated: true)
        } else if !overlays.isEmpty {
            var rect = overlays[0].boundingMapRect
            for overlay in overlays.dropFirst() { rect = rect.union(overlay.boundingMapRect) }
            mapView.setVisibleMapRect(rect,
                                      edgePadding: UIEdgeInsets(top: 60, left: 40, bottom: 60, right: 40),
                                      animated: false)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(Color.cityAccent)
            renderer.lineWidth = 6
            return renderer
        }
    }
}
