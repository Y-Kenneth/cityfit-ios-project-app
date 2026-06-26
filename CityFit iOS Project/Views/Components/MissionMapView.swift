import SwiftUI
import MapKit

/// Live map for an active mission (UIKit bridge — iOS 16 SwiftUI Map cannot
/// draw polyline overlays). Same 3D-tilted look, custom walking avatar, zoom
/// limits and follow behaviour as the Home map (HomeMapView) — it reuses
/// HomeMapView's camera constants so the two stay identical — plus the walked
/// trail and an optional destination pin specific to an active mission.
struct MissionMapView: UIViewRepresentable {
    let userLocation: CLLocationCoordinate2D?
    let trail: [CLLocationCoordinate2D]
    let destination: CLLocationCoordinate2D?
    let heading: CLLocationDirection
    let isMoving: Bool
    let character: CharacterType
    /// Bumped by the parent's recenter button to re-engage following after the
    /// user has panned away.
    var recenterTrigger: Int = 0

    /// Same Nanjing fallback LocationService uses — only seeds the very first
    /// frame if a GPS fix hasn't arrived yet, so the map never opens on MapKit's
    /// own default region (a US location) while waiting.
    private static let fallbackCenter = CLLocationCoordinate2D(latitude: 32.0603, longitude: 118.7964)

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = false   // replaced by our own avatar annotation
        mapView.showsCompass = false
        mapView.isRotateEnabled = false
        mapView.setCameraZoomRange(
            MKMapView.CameraZoomRange(minCenterCoordinateDistance: HomeMapView.minCameraDistance,
                                      maxCenterCoordinateDistance: HomeMapView.maxCameraDistance),
            animated: false)
        mapView.camera = MKMapCamera(lookingAtCenter: userLocation ?? MissionMapView.fallbackCenter,
                                     fromDistance: HomeMapView.defaultCameraDistance,
                                     pitch: HomeMapView.cameraPitch,
                                     heading: 0)
        // Delegate set last so the initial camera setup isn't mistaken for a pan.
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.character = character
        context.coordinator.heading = heading

        // Trail polyline (redraw each update — point counts stay modest):
        // a soft wide glow underneath, a crisp dashed core on top.
        mapView.removeOverlays(mapView.overlays)
        if trail.count >= 2 {
            mapView.addOverlay(GlowPolyline(coordinates: trail, count: trail.count))
            mapView.addOverlay(MKPolyline(coordinates: trail, count: trail.count))
        }

        // Destination pin — added once (it doesn't move during a mission).
        if let destination, !mapView.annotations.contains(where: { $0 is MKPointAnnotation }) {
            let pin = MKPointAnnotation()
            pin.coordinate = destination
            pin.title = "Destination"
            mapView.addAnnotation(pin)
        }

        // Avatar: mutate in place (smoothly animates via KVO) instead of
        // remove-and-readd, which would flicker on every heading tick.
        if let userLocation {
            if let avatar = mapView.annotations.compactMap({ $0 as? AvatarAnnotation }).first {
                avatar.coordinate = userLocation
                if let view = mapView.view(for: avatar) {
                    context.coordinator.refreshAvatarImage(view, character: character, heading: heading)
                    context.coordinator.setBobbing(isMoving, on: view)
                }
            } else {
                mapView.addAnnotation(AvatarAnnotation(coordinate: userLocation))
            }
        }

        // Camera follow — same drift-based logic as HomeMapView: re-center
        // whenever the MAP has drifted from the user (covers MapKit resetting
        // the camera to its default region after the zero-sized map resolves its
        // bounds, and rides a coarse first GPS fix to the corrected one).
        // Switched off the moment the user pans (regionWillChange + live touch).
        if let target = userLocation, context.coordinator.isFollowingUser {
            let current = mapView.camera.centerCoordinate
            let drift = CLLocation(latitude: current.latitude, longitude: current.longitude)
                .distance(from: CLLocation(latitude: target.latitude, longitude: target.longitude))
            if drift > 5 {
                setCamera(on: mapView, center: target, animated: false)
            }
        }

        // Self-heal: reassert pitch/heading if MapKit flattens the camera when
        // the map first resolves its bounds. Preserves the center.
        if abs(mapView.camera.pitch - HomeMapView.cameraPitch) > 1 || abs(mapView.camera.heading) > 1 {
            let camera = mapView.camera.copy() as! MKMapCamera
            camera.pitch = HomeMapView.cameraPitch
            camera.heading = 0
            mapView.setCamera(camera, animated: false)
        }

        // Recenter button: re-engage following and snap back to the user.
        if recenterTrigger != context.coordinator.lastRecenterTrigger {
            context.coordinator.lastRecenterTrigger = recenterTrigger
            context.coordinator.isFollowingUser = true
            if let target = userLocation {
                setCamera(on: mapView, center: target, animated: true)
            }
        }
    }

    private func setCamera(on mapView: MKMapView, center: CLLocationCoordinate2D, animated: Bool) {
        let camera = MKMapCamera(lookingAtCenter: center,
                                 fromDistance: HomeMapView.defaultCameraDistance,
                                 pitch: HomeMapView.cameraPitch,
                                 heading: 0)
        mapView.setCamera(camera, animated: animated)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var isFollowingUser = true
        var lastRecenterTrigger = 0
        var character: CharacterType = .sportsmanM
        var heading: CLLocationDirection = 0

        // A region change driven by a live touch gesture is the user panning —
        // stop following so we don't fight them. Programmatic/layout changes
        // have no active gesture, so following keeps going (same approach as
        // HomeMapView).
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            if Self.hasActiveGesture(in: mapView) {
                isFollowingUser = false
            }
        }

        private static func hasActiveGesture(in view: UIView) -> Bool {
            if let gestures = view.gestureRecognizers,
               gestures.contains(where: { $0.state == .began || $0.state == .changed }) {
                return true
            }
            return view.subviews.contains { hasActiveGesture(in: $0) }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let avatarAnnotation = annotation as? AvatarAnnotation else { return nil }
            let identifier = "avatarPin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.zPriority = .max
            view.image = Self.renderImage(UserAvatarPinView(emoji: character.emoji, heading: heading))
            return view
        }

        func refreshAvatarImage(_ view: MKAnnotationView, character: CharacterType, heading: CLLocationDirection) {
            view.image = Self.renderImage(UserAvatarPinView(emoji: character.emoji, heading: heading))
        }

        /// Loops a gentle scale pulse while walking; stops (and resets) when stationary.
        func setBobbing(_ isMoving: Bool, on view: MKAnnotationView) {
            let isAnimating = view.layer.animation(forKey: "bob") != nil
            if isMoving && !isAnimating {
                let animation = CABasicAnimation(keyPath: "transform.scale")
                animation.fromValue = 1.0
                animation.toValue = 1.12
                animation.duration = 0.3
                animation.autoreverses = true
                animation.repeatCount = .infinity
                view.layer.add(animation, forKey: "bob")
            } else if !isMoving && isAnimating {
                view.layer.removeAnimation(forKey: "bob")
            }
        }

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

        static func renderImage<V: View>(_ view: V) -> UIImage {
            let renderer = ImageRenderer(content: view)
            renderer.scale = UIScreen.main.scale
            return renderer.uiImage ?? UIImage()
        }
    }
}

/// A walking-avatar annotation (mirrors HomeMapView's own private one).
private final class AvatarAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D) { self.coordinate = coordinate }
}

/// Tags the wide soft-glow underlay so the renderer can tell it apart from the
/// crisp dashed line drawn on top of it.
private final class GlowPolyline: MKPolyline {}
