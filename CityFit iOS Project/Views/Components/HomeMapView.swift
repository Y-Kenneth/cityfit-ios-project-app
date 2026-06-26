import SwiftUI
import MapKit

/// 3D-tilted version of the Home map (UIKit bridge — SwiftUI's
/// Map(coordinateRegion:) has no camera/pitch control, so a real MKMapView
/// is needed to get MapKit's native extruded-building 3D look, same reason
/// NavigationMapView/MissionMapView already bridge to UIKit elsewhere).
///
/// Mission/event pins reuse the existing MissionPinView, snapshotted via
/// ImageRenderer so the visuals stay identical to the old 2D map. The user's
/// own position is a custom avatar pin (not the default blue dot) that
/// rotates with the device's real compass heading and bobs while walking.
struct HomeMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let userLocation: CLLocationCoordinate2D?
    let pins: [MapPinItem]
    let character: CharacterType
    let heading: CLLocationDirection
    let isMoving: Bool
    let isPlanningTrip: Bool
    let onSelectPin: (MapPinItem) -> Void
    let onMapTap: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false   // replaced by our own avatar annotation
        mapView.showsCompass = false
        // Keep the map itself north-up — the avatar's heading cone is computed
        // relative to true north, so a manually-rotated map would throw it off.
        mapView.isRotateEnabled = false
        mapView.camera = MKMapCamera(lookingAtCenter: region.center,
                                     fromDistance: 650,
                                     pitch: 55,
                                     heading: 0)
        // Only active in "Plan a Walk" mode (see isEnabled below) so it never
        // competes with the existing pin-didSelect flow during normal browsing.
        let tapGesture = UITapGestureRecognizer(target: context.coordinator,
                                                action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.onSelectPin = onSelectPin
        context.coordinator.onMapTap = onMapTap
        mapView.gestureRecognizers?
            .compactMap { $0 as? UITapGestureRecognizer }
            .forEach { $0.isEnabled = isPlanningTrip }
        // Cached so a freshly-created avatar view (mapView(_:viewFor:)) has
        // something to render immediately, before the "mutate in place"
        // branch below ever runs for it.
        context.coordinator.character = character
        context.coordinator.heading = heading

        // Pins: cheap remove-and-readd, but only when the set actually
        // changed — this runs on every heading/isMoving update too, so a
        // naive always-readd would make mission/event pins flicker constantly.
        let pinAnnotations = mapView.annotations.compactMap { $0 as? PinAnnotation }
        if pinAnnotations.map(\.pin.id) != pins.map(\.id) {
            mapView.removeAnnotations(pinAnnotations)
            mapView.addAnnotations(pins.map(PinAnnotation.init))
        }

        // Avatar: mutate the existing annotation in place (smoothly animates
        // position via KVO) instead of remove-and-readd, which would flicker
        // on every heading tick.
        let avatarCoordinate = userLocation ?? region.center
        if let avatar = mapView.annotations.compactMap({ $0 as? AvatarAnnotation }).first {
            avatar.coordinate = avatarCoordinate
            if let view = mapView.view(for: avatar) {
                context.coordinator.refreshAvatarImage(view, character: character, heading: heading)
                context.coordinator.setBobbing(isMoving, on: view)
            }
        } else {
            mapView.addAnnotation(AvatarAnnotation(coordinate: avatarCoordinate))
        }

        // Pitch/heading self-heal: MapKit can silently flatten the camera
        // back to a 2D top-down view once the (initially zero-sized) map
        // view resolves its real on-screen bounds after creation — so this
        // can't be a one-time setup in makeUIView, it has to be reasserted
        // here. This only touches pitch/heading, never centerCoordinate, so
        // it can't fight the user's own panning.
        if abs(mapView.camera.pitch - 55) > 1 || abs(mapView.camera.heading) > 1 {
            let camera = mapView.camera.copy() as! MKMapCamera
            camera.pitch = 55
            camera.heading = 0
            mapView.setCamera(camera, animated: false)
        }

        // Camera center: only re-center when `region.center` ITSELF changed
        // since the last call (first GPS fix, or the recenter button) — not
        // whenever the camera's current position differs from it, which is
        // also true the instant the user pans away. Comparing against the
        // camera's live position (the old, buggy check) snapped the map back
        // to the user every few seconds, since this method re-runs on every
        // heading tick.
        let lastCenter = context.coordinator.lastKnownRegionCenter
        let regionMoved = lastCenter.map {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                .distance(from: CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)) > 3
        } ?? false
        context.coordinator.lastKnownRegionCenter = region.center

        if regionMoved {
            let camera = mapView.camera.copy() as! MKMapCamera
            camera.centerCoordinate = region.center
            mapView.setCamera(camera, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var onSelectPin: ((MapPinItem) -> Void)?
        var onMapTap: ((CLLocationCoordinate2D) -> Void)?
        var character: CharacterType = .sportsmanM
        var heading: CLLocationDirection = 0
        var lastKnownRegionCenter: CLLocationCoordinate2D?

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            onMapTap?(coordinate)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let pinAnnotation = annotation as? PinAnnotation {
                let identifier = "missionPin"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.image = Self.renderImage(MissionPinView(pin: pinAnnotation.pin))
                return view
            }
            if let avatarAnnotation = annotation as? AvatarAnnotation {
                let identifier = "avatarPin"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.zPriority = .max
                view.image = Self.renderImage(UserAvatarPinView(emoji: character.emoji, heading: heading))
                return view
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            defer { mapView.deselectAnnotation(annotation, animated: false) }
            guard let pinAnnotation = annotation as? PinAnnotation, pinAnnotation.pin.kind == .event else { return }
            onSelectPin?(pinAnnotation.pin)
        }

        func refreshAvatarImage(_ view: MKAnnotationView, character: CharacterType, heading: CLLocationDirection) {
            view.image = Self.renderImage(UserAvatarPinView(emoji: character.emoji, heading: heading))
        }

        /// Loops a gentle scale pulse while walking; stops (and resets scale) when stationary.
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

        static func renderImage<V: View>(_ view: V) -> UIImage {
            let renderer = ImageRenderer(content: view)
            renderer.scale = UIScreen.main.scale
            return renderer.uiImage ?? UIImage()
        }
    }
}

private final class PinAnnotation: NSObject, MKAnnotation {
    let pin: MapPinItem
    var coordinate: CLLocationCoordinate2D { pin.coordinate }
    init(pin: MapPinItem) { self.pin = pin }
}

private final class AvatarAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D) { self.coordinate = coordinate }
}
