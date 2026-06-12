import Foundation
import CoreLocation
import MapKit

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 32.0603, longitude: 118.7964), // Nanjing fallback
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var trackedDistance: Double = 0   // meters accumulated during an active mission
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private var hasCenteredOnUser = false
    private var isTrackingDistance = false
    private var lastTrackedLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func centerOnUser() {
        guard let location = userLocation else { return }
        region = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    func startDistanceTracking() {
        trackedDistance = 0
        lastTrackedLocation = nil
        isTrackingDistance = true
    }

    func stopDistanceTracking() {
        isTrackingDistance = false
        lastTrackedLocation = nil
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate

            // Only auto-center on the first fix so the user can pan freely afterwards
            if !self.hasCenteredOnUser {
                self.hasCenteredOnUser = true
                self.region.center = location.coordinate
            }

            if self.isTrackingDistance, location.horizontalAccuracy < 50 {
                if let last = self.lastTrackedLocation {
                    let delta = location.distance(from: last)
                    if delta < 100 { // ignore GPS jumps
                        self.trackedDistance += delta
                    }
                }
                self.lastTrackedLocation = location
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // GPS unavailable (e.g. simulator without a simulated location) — keep the fallback region
    }
}
