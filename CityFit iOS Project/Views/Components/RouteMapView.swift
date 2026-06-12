import SwiftUI
import MapKit

/// UIKit bridge used only by RoutePreviewView: the iOS 16 SwiftUI Map
/// cannot draw polyline overlays, so the AI route preview uses MKMapView.
struct RouteMapView: UIViewRepresentable {
    let overlays: [MKPolyline]
    let waypoints: [RouteResponse.Waypoint]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        mapView.addOverlays(overlays)

        for (index, waypoint) in waypoints.enumerated() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = waypoint.coordinate
            annotation.title = "\(index + 1). \(waypoint.title)"
            mapView.addAnnotation(annotation)
        }

        if let first = overlays.first {
            var rect = first.boundingMapRect
            for overlay in overlays.dropFirst() {
                rect = rect.union(overlay.boundingMapRect)
            }
            mapView.setVisibleMapRect(rect,
                                      edgePadding: UIEdgeInsets(top: 50, left: 40, bottom: 50, right: 40),
                                      animated: false)
        } else if let first = waypoints.first {
            mapView.setRegion(MKCoordinateRegion(
                center: first.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)), animated: false)
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
            renderer.lineWidth = 5
            return renderer
        }
    }
}
