import SwiftUI
import MapKit

/// Live map for an active mission (UIKit bridge — iOS 16 SwiftUI Map cannot
/// draw polyline overlays). Shows the user's location, the trail they've
/// walked so far, and an optional destination pin. Follows the user.
struct MissionMapView: UIViewRepresentable {
    let userLocation: CLLocationCoordinate2D?
    let trail: [CLLocationCoordinate2D]
    let destination: CLLocationCoordinate2D?
    /// Bumped by the parent's recenter button to re-engage tracking after the
    /// user has panned away — panning the map is a standard MapKit gesture
    /// that drops `userTrackingMode` back to `.none`, same as Apple/Google Maps.
    var recenterTrigger: Int = 0

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        // .follow hands the "wait for the first GPS fix, then zoom/center on
        // the user" sequence to MapKit itself — the same mechanism Apple Maps
        // and Google Maps use, including their brief default view before the
        // first fix arrives. A previous version of this code seeded a
        // hardcoded fallback center instead, which made the user's own blue
        // dot disappear off-screen on real devices far from that point —
        // don't reintroduce a fake center here.
        mapView.userTrackingMode = .follow
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Trail polyline (redraw each update — point counts stay modest).
        // Drawn as two overlays: a soft wide glow underneath, a crisp dashed
        // core on top — reads as a deliberate "live trail," not a flat line.
        mapView.removeOverlays(mapView.overlays)
        if trail.count >= 2 {
            mapView.addOverlay(GlowPolyline(coordinates: trail, count: trail.count))
            mapView.addOverlay(MKPolyline(coordinates: trail, count: trail.count))
        }

        // Destination pin (if the mission has a target location).
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        if let destination {
            let pin = MKPointAnnotation()
            pin.coordinate = destination
            pin.title = "Destination"
            mapView.addAnnotation(pin)
        }

        if context.coordinator.lastRecenterTrigger != recenterTrigger {
            context.coordinator.lastRecenterTrigger = recenterTrigger
            mapView.setUserTrackingMode(.follow, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var lastRecenterTrigger = 0

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            if polyline is GlowPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(Color.cityAccent).withAlphaComponent(0.25)
                renderer.lineWidth = 14
                renderer.lineCap = .round
                return renderer
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(Color.cityAccent)
            renderer.lineWidth = 5
            renderer.lineCap = .round
            renderer.lineJoin = .round
            renderer.lineDashPattern = [0, 14]
            return renderer
        }
    }
}

/// Tags the wide soft-glow underlay so the renderer can tell it apart from the
/// crisp dashed line drawn on top of it.
private final class GlowPolyline: MKPolyline {}
