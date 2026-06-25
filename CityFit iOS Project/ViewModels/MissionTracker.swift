import Foundation
import CoreLocation
import Combine

/// Feeds the map-based active-mission screen: the user's live location and the
/// trail they've walked. On device this mirrors real GPS from LocationService.
/// On the Simulator (no real movement) it walks the user outward so the dot and
/// trail move for demos — mirroring how PedometerService mocks steps.
@MainActor
final class MissionTracker: ObservableObject {

    @Published private(set) var userLocation: CLLocationCoordinate2D?
    @Published private(set) var trail: [CLLocationCoordinate2D] = []

    private let mission: Mission?
    private var cancellable: AnyCancellable?

    init(mission: Mission?) {
        self.mission = mission
    }

    func start(locationService: LocationService) {
        cancellable = locationService.$userLocation
            .compactMap { $0 }
            .sink { [weak self] coordinate in
                self?.append(coordinate)
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

    private func append(_ coordinate: CLLocationCoordinate2D) {
        userLocation = coordinate
        // Only record meaningful movement so the trail stays clean.
        if let last = trail.last {
            let a = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let b = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            guard b.distance(from: a) >= 3 else { return }
        }
        trail.append(coordinate)
    }

    // MARK: - Simulator mock walk

    #if targetEnvironment(simulator)
    private var simulatorTimer: Timer?

    private func startSimulatedWalk() {
        // Start at the mission pin if it has one, else a Nanjing fallback.
        var current = mission?.coordinate
            ?? CLLocationCoordinate2D(latitude: 32.0603, longitude: 118.7964)
        append(current)

        // Step roughly north-east each tick (~5–6 m) so distance accrues.
        simulatorTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                current.latitude += 0.00004
                current.longitude += 0.00003
                self.append(current)
            }
        }
    }
    #endif
}
