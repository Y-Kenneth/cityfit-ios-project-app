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
        seedInitialRegionIfNeeded(mapView, context: context)
        // .follow hands ongoing tracking to MapKit itself — same mechanism
        // Apple Maps and Google Maps use.
        mapView.userTrackingMode = .follow
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        seedInitialRegionIfNeeded(mapView, context: context)

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

    /// showsUserLocation + .follow spin up MKMapView's OWN internal
    /// CLLocationManager, separate from the app's already-running
    /// LocationService — it needs its own fresh GPS fix, which briefly shows
    /// MapKit's default world view first. But the app's LocationService has
    /// almost always already got a real fix by the time this screen opens
    /// (it's been running since app launch), passed in here via
    /// `userLocation`. Seed the camera with that real coordinate the first
    /// time it's available — whether that's already true at `makeUIView`, or
    /// only arrives a moment later via `updateUIView` (SwiftUI can render
    /// this view's body, and thus call `makeUIView`, before the parent's
    /// `.onAppear` populates `userLocation`) — so the map opens in the right
    /// place instead of waiting on MapKit's separate fix. This is the user's
    /// actual current location, not a guess — unlike the previous hardcoded
    /// fallback center this code used to seed (removed because it made the
    /// blue dot disappear off-screen on devices far from that point), so it
    /// can't reintroduce that bug. Guarded to run once so it never fights
    /// `.follow` or the user's own panning afterward.
    private func seedInitialRegionIfNeeded(_ mapView: MKMapView, context: Context) {
        guard !context.coordinator.hasSeededInitialRegion, let userLocation else { return }
        context.coordinator.hasSeededInitialRegion = true
        mapView.setRegion(MKCoordinateRegion(center: userLocation,
                                              latitudinalMeters: 600,
                                              longitudinalMeters: 600),
                           animated: false)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var lastRecenterTrigger = 0
        var hasSeededInitialRegion = false

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
