import Foundation
import CoreMotion

/// Step + distance source. CMPedometer does NOT work on the Simulator,
/// so a mock timer feeds fake data there instead.
final class PedometerService: ObservableObject {
    @Published var stepCount: Int = 0
    @Published var distance: Double = 0.0

    #if targetEnvironment(simulator)
    private var mockTimer: Timer?

    func startTracking() {
        stepCount = 0
        distance = 0
        mockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.stepCount += 3
                self?.distance += 2.5
            }
        }
    }

    func stopTracking() {
        mockTimer?.invalidate()
        mockTimer = nil
    }
    #else
    private let pedometer = CMPedometer()

    func startTracking() {
        stepCount = 0
        distance = 0
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                self?.stepCount = data.numberOfSteps.intValue
                self?.distance = data.distance?.doubleValue ?? 0
            }
        }
    }

    func stopTracking() {
        pedometer.stopUpdates()
    }
    #endif
}
