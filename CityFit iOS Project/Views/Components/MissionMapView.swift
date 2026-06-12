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
        mapView.removeOverlays(mapView.overlays)
        if trail.count >= 2 {
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
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(Color.cityGreen)
            renderer.lineWidth = 6
            return renderer
        }
    }
}
