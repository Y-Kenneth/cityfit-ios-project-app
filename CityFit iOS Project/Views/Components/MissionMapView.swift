import SwiftUI
import MapKit

/// Live map for an active mission (UIKit bridge — iOS 16 SwiftUI Map cannot
/// draw polyline overlays). Shows the user's location, the trail they've
/// walked so far, and an optional destination pin. Follows the user.
struct MissionMapView: UIViewRepresentable {
    let userLocation: CLLocationCoordinate2D?
    let trail: [CLLocationCoordinate2D]
    let destination: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
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

        // Follow the user at a navigation-style zoom.
        if let userLocation {
            let region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004))
            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
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
