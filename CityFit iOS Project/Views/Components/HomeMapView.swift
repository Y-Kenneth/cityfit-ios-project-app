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
    /// Bumped by the parent's recenter button — re-snaps the camera to the
    /// user even when they only panned the map (so the center value itself
    /// didn't change), which the old center-distance check couldn't detect.
    let recenterTrigger: Int
    /// "Plan a Walk" tapped points — drawn as start/finish markers.
    let tripOrigin: CLLocationCoordinate2D?
    let tripDestination: CLLocationCoordinate2D?
    let onSelectPin: (MapPinItem) -> Void
    let onMapTap: (CLLocationCoordinate2D) -> Void

    // Camera tuning — kept as constants so the initial camera, the self-heal,
    // and the recenter all agree on the same close-in 3D framing.
    static let cameraPitch: CGFloat = 55
    static let defaultCameraDistance: CLLocationDistance = 650
    static let minCameraDistance: CLLocationDistance = 250
    /// Hard ceiling on zoom-out. Set to a whole-city view (≈ Nanjing-wide) so
    /// the user can pull back well beyond a single district, while still being
    /// capped so the map can never resolve to the zoomed-out "blue world".
    /// It's a pure zoom limit (no pan boundary), so hitting it never moves the
    /// map's center — the map just stops zooming out where it is.
    static let maxCameraDistance: CLLocationDistance = 45_000

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = false   // replaced by our own avatar annotation
        mapView.showsCompass = false
        // Keep the map itself north-up — the avatar's heading cone is computed
        // relative to true north, so a manually-rotated map would throw it off.
        mapView.isRotateEnabled = false
        // Clamp zoom up-front so even the very first layout pass can never
        // resolve to the zoomed-out blue world.
        mapView.setCameraZoomRange(
            MKMapView.CameraZoomRange(minCenterCoordinateDistance: HomeMapView.minCameraDistance,
                                      maxCenterCoordinateDistance: HomeMapView.maxCameraDistance),
            animated: false)
        mapView.camera = MKMapCamera(lookingAtCenter: region.center,
                                     fromDistance: HomeMapView.defaultCameraDistance,
                                     pitch: HomeMapView.cameraPitch,
                                     heading: 0)
        // Only active in "Plan a Walk" mode (see isEnabled below) so it never
        // competes with the existing pin-didSelect flow during normal browsing.
        let tapGesture = UITapGestureRecognizer(target: context.coordinator,
                                                action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        mapView.delegate = context.coordinator
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

        // Trip-planning start/finish markers: re-synced only when the tapped
        // points change (same diff-before-readd approach as the pins above, so
        // they don't flicker on every heading tick).
        let tripSignature = [tripOrigin, tripDestination]
            .map { $0.map { "\($0.latitude),\($0.longitude)" } ?? "-" }
            .joined(separator: "|")
        if tripSignature != context.coordinator.lastTripSignature {
            context.coordinator.lastTripSignature = tripSignature
            mapView.removeAnnotations(mapView.annotations.compactMap { $0 as? TripPointAnnotation })
            var markers: [TripPointAnnotation] = []
            if let tripOrigin { markers.append(TripPointAnnotation(coordinate: tripOrigin, kind: .start)) }
            if let tripDestination { markers.append(TripPointAnnotation(coordinate: tripDestination, kind: .destination)) }
            mapView.addAnnotations(markers)
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

        // Camera — keep following the user's GPS position until they actually
        // touch the map. Following (not centering once) is what survives a bad
        // first location fix: on launch, especially in China behind a VPN, iOS
        // can hand over a wrong network-assisted fix before GPS locks; centering
        // once froze the map on that wrong country. By following, the camera
        // tracks straight to the corrected position the instant GPS provides it,
        // with no manual recenter. The moment the user pans/zooms for real, the
        // regionWillChange delegate (which checks for a live touch gesture, so it
        // ignores our own programmatic moves and MapKit's launch layout) turns
        // following off so we never fight their browsing.
        let target = userLocation ?? region.center
        if context.coordinator.isFollowingUser {
            let last = context.coordinator.lastFollowedCenter
            let moved = last.map {
                CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                    .distance(from: CLLocation(latitude: target.latitude, longitude: target.longitude)) > 2
            } ?? true
            if moved {
                context.coordinator.lastFollowedCenter = target
                setCamera(on: mapView, center: target, animated: last != nil)
            }
        }

        // Self-heal: MapKit can flatten the camera to a top-down view once the
        // initially-zero-sized map resolves its real bounds. Reassert
        // pitch/heading only — it copies the current camera, so it preserves the
        // center and never fights the user's panning.
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
            context.coordinator.lastFollowedCenter = target
            setCamera(on: mapView, center: target, animated: true)
        }
    }

    /// Snaps the camera to the standard close-in 3D framing centered on `center`.
    private func setCamera(on mapView: MKMapView, center: CLLocationCoordinate2D, animated: Bool) {
        let camera = MKMapCamera(lookingAtCenter: center,
                                 fromDistance: HomeMapView.defaultCameraDistance,
                                 pitch: HomeMapView.cameraPitch,
                                 heading: 0)
        mapView.setCamera(camera, animated: animated)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var onSelectPin: ((MapPinItem) -> Void)?
        var onMapTap: ((CLLocationCoordinate2D) -> Void)?
        var character: CharacterType = .sportsmanM
        var heading: CLLocationDirection = 0
        /// While true the camera tracks the user's GPS position every update.
        /// Stays true through launch layout and our own programmatic moves, and
        /// only flips off when the user physically pans/zooms (see regionWillChange).
        var isFollowingUser = true
        var lastFollowedCenter: CLLocationCoordinate2D?
        var lastRecenterTrigger = 0
        var lastTripSignature = ""

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            onMapTap?(coordinate)
        }

        // Stop auto-following only when the region change is driven by a LIVE
        // touch gesture — i.e. the user actually dragging/pinching the map.
        // MapKit also fires this during its initial layout and for our own
        // setCamera calls, but no gesture is mid-flight then, so following keeps
        // going (which is what lets the camera ride a bad first GPS fix through
        // to the corrected position). This touch-state check is the reliable way
        // to tell user input from programmatic/system moves.
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            if Self.hasActiveGesture(in: mapView) {
                isFollowingUser = false
            }
        }

        /// True if any gesture recognizer anywhere in the map's view hierarchy is
        /// currently mid-interaction (the user's finger is down and moving).
        private static func hasActiveGesture(in view: UIView) -> Bool {
            if let gestures = view.gestureRecognizers,
               gestures.contains(where: { $0.state == .began || $0.state == .changed }) {
                return true
            }
            return view.subviews.contains { hasActiveGesture(in: $0) }
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
            if let tripPoint = annotation as? TripPointAnnotation {
                let identifier = "tripPoint"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                let image = Self.renderImage(TripPointMarker(kind: tripPoint.kind))
                view.image = image
                // Anchor the pin's pointed tip on the exact tapped coordinate.
                view.centerOffset = CGPoint(x: 0, y: -image.size.height / 2)
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

/// A "Plan a Walk" tapped point — start or destination.
private final class TripPointAnnotation: NSObject, MKAnnotation {
    enum Kind { case start, destination }
    let coordinate: CLLocationCoordinate2D
    let kind: Kind
    init(coordinate: CLLocationCoordinate2D, kind: Kind) {
        self.coordinate = coordinate
        self.kind = kind
    }
}

/// Teardrop marker (circle + downward pointer) drawn at a trip start/finish.
private struct TripPointMarker: View {
    let kind: TripPointAnnotation.Kind

    private var color: Color { kind == .start ? .cityGreen : .cityAccent }
    private var icon: String { kind == .start ? "figure.walk" : "flag.checkered" }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                Image(systemName: icon)
                    .font(.game(size: 15, weight: .bold))
                    .foregroundColor(.black)
            }
            TripPinPointer()
                .fill(color)
                .frame(width: 14, height: 9)
        }
    }
}

/// Downward-pointing triangle whose tip sits at the bottom (the map coordinate).
private struct TripPinPointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
