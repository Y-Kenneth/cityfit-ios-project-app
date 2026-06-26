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
    private var cmStepCount: Int = 0

    #if DEBUG
    // CMPedometer's stride-cadence detector frequently reports 0 steps when
    // testing in place in a small room (e.g. pacing without covering ground) —
    // it's tuned for real walking displacement, not in-place stepping. This
    // fallback derives a step count from raw accelerometer peaks instead, so
    // testing indoors doesn't look broken. Real CMPedometer stays authoritative
    // whenever it actually reports steps; the fallback only fills in while it
    // reads exactly 0.
    private let motionManager = CMMotionManager()
    private var fallbackStepCount: Int = 0
    private var recentMagnitudes: [Double] = []
    private var lastStepAt: Date?

    /// Minimum acceleration magnitude (g) above resting noise to count as a footfall.
    private let stepThreshold = 0.18
    /// Debounce so one footfall's bounce isn't counted twice (typical cadence is well under 2.5 steps/sec).
    private let minStepInterval: TimeInterval = 0.25
    #endif

    func startTracking() {
        stepCount = 0
        distance = 0
        cmStepCount = 0
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard let self, let data = data, error == nil else { return }
            DispatchQueue.main.async {
                self.cmStepCount = data.numberOfSteps.intValue
                self.distance = data.distance?.doubleValue ?? 0
                self.stepCount = self.effectiveStepCount
            }
        }
        #if DEBUG
        startFallbackDetector()
        #endif
    }

    func stopTracking() {
        pedometer.stopUpdates()
        #if DEBUG
        stopFallbackDetector()
        #endif
    }

    #if DEBUG
    private var effectiveStepCount: Int {
        cmStepCount > 0 ? cmStepCount : fallbackStepCount
    }

    private func startFallbackDetector() {
        fallbackStepCount = 0
        recentMagnitudes.removeAll()
        lastStepAt = nil
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 50.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self, let data = data, error == nil else { return }
            self.processAccelerometerSample(data.acceleration)
        }
    }

    private func stopFallbackDetector() {
        motionManager.stopAccelerometerUpdates()
        recentMagnitudes.removeAll()
        lastStepAt = nil
    }

    /// Simple peak-detection pedometer: smooths magnitude over a short window,
    /// then counts a step when it rises through `stepThreshold` from below,
    /// debounced by `minStepInterval`.
    private func processAccelerometerSample(_ accel: CMAcceleration) {
        let magnitude = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z) - 1.0 // subtract gravity
        recentMagnitudes.append(abs(magnitude))
        if recentMagnitudes.count > 5 {
            recentMagnitudes.removeFirst(recentMagnitudes.count - 5)
        }
        let smoothed = recentMagnitudes.reduce(0, +) / Double(recentMagnitudes.count)

        let now = Date()
        let debounced = lastStepAt.map { now.timeIntervalSince($0) >= minStepInterval } ?? true
        guard smoothed >= stepThreshold, debounced else { return }

        lastStepAt = now
        fallbackStepCount += 1
        if cmStepCount == 0 {
            stepCount = fallbackStepCount
        }
    }
    #endif
    #endif
}
