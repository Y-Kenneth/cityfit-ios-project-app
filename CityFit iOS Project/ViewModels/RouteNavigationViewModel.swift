import Foundation
import CoreLocation
import Combine

/// Drives the live route-navigation screen: tracks which waypoint is next,
/// distance to it, and total distance remaining along the route.
///
/// On device this consumes real GPS via LocationService. On the Simulator
/// (no real movement) it animates the user along the route so the demo's
/// distances tick down — mirroring how PedometerService mocks steps.
@MainActor
final class RouteNavigationViewModel: ObservableObject {

    @Published private(set) var userLocation: CLLocationCoordinate2D?
    @Published private(set) var nextWaypointIndex = 0
    @Published private(set) var distanceToNext: Double = 0      // meters
    @Published private(set) var distanceRemaining: Double = 0   // meters, to final waypoint
    @Published private(set) var arrived = false

    private let waypoints: [RouteResponse.Waypoint]
    private let locationService: LocationService
    private var cancellable: AnyCancellable?

    /// How close (meters) counts as reaching a waypoint.
    private let arrivalRadius: Double = 25

    init(waypoints: [RouteResponse.Waypoint], locationService: LocationService) {
        self.waypoints = waypoints
        self.locationService = locationService
    }

    var nextWaypointTitle: String {
        guard nextWaypointIndex < waypoints.count else { return "Destination" }
        return waypoints[nextWaypointIndex].title
    }

    var totalWaypoints: Int { waypoints.count }

    func start() {
        // React to live GPS updates.
        cancellable = locationService.$userLocation
            .compactMap { $0 }
            .sink { [weak self] coordinate in
                self?.update(with: coordinate)
            }

        #if targetEnvironment(simulator)
        startSimulatedWalk()
        #endif
    }

    func stop() {
        cancellable?.cancel()
        cancellable = nil
        #if targetEnvironment(simulator)
        simulatorTimer?.invalidate()
        simulatorTimer = nil
        #endif
    }

    // MARK: - Core update

    private func update(with coordinate: CLLocationCoordinate2D) {
        guard !arrived, nextWaypointIndex < waypoints.count else { return }
        userLocation = coordinate

        let here = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        // Distance to the next waypoint.
        let next = waypoints[nextWaypointIndex].coordinate
        let nextLoc = CLLocation(latitude: next.latitude, longitude: next.longitude)
        distanceToNext = here.distance(from: nextLoc)

        // Advance when within arrival radius.
        if distanceToNext <= arrivalRadius {
            nextWaypointIndex += 1
            if nextWaypointIndex >= waypoints.count {
                arrived = true
                distanceToNext = 0
                distanceRemaining = 0
                return
            }
        }

        recomputeRemaining(from: coordinate)
    }

    /// Remaining = distance to the next waypoint + straight-line legs between
    /// all subsequent waypoints.
    private func recomputeRemaining(from coordinate: CLLocationCoordinate2D) {
        guard nextWaypointIndex < waypoints.count else {
            distanceRemaining = 0
            return
        }
        var total = distanceToNext
        var index = nextWaypointIndex
        while index < waypoints.count - 1 {
            let a = waypoints[index].coordinate
            let b = waypoints[index + 1].coordinate
            let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
            let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
            total += locB.distance(from: locA)
            index += 1
        }
        distanceRemaining = total
    }

    // MARK: - Simulator mock walk

    #if targetEnvironment(simulator)
    private var simulatorTimer: Timer?
    private var simulatedProgress: Double = 0   // 0...1 along the whole route

    /// Interpolates the user along the waypoint path so distances tick down.
    private func startSimulatedWalk() {
        guard waypoints.count >= 1 else { return }
        // Seed at the first waypoint so the route is in view immediately.
        update(with: waypoints[0].coordinate)

        let legCount = max(waypoints.count - 1, 1)
        simulatorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard !self.arrived else { return }
                self.simulatedProgress = min(self.simulatedProgress + 0.01, 1.0)

                // Map overall progress onto the current leg.
                let scaled = self.simulatedProgress * Double(legCount)
                let leg = min(Int(scaled), legCount - 1)
                let t = scaled - Double(leg)
                let a = self.waypoints[leg].coordinate
                let b = self.waypoints[min(leg + 1, self.waypoints.count - 1)].coordinate
                let lat = a.latitude + (b.latitude - a.latitude) * t
                let lng = a.longitude + (b.longitude - a.longitude) * t
                self.update(with: CLLocationCoordinate2D(latitude: lat, longitude: lng))
            }
        }
    }
    #endif
}
