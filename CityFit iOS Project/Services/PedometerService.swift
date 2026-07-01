import Foundation
import CoreMotion

// tracks steps and distance. on Simulator, sends fake data since CMPedometer doesn't work there.
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
    // CMPedometer often reads 0 when walking in place indoors.
    // this fallback counts steps from accelerometer peaks when CMPedometer reports 0.
    private let motionManager = CMMotionManager()
    private var fallbackStepCount: Int = 0
    private var recentMagnitudes: [Double] = []
    private var lastStepAt: Date?

    private let stepThreshold = 0.18        // min acceleration to count as a step
    private let minStepInterval: TimeInterval = 0.25  // prevents counting the same step twice
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

    // counts steps from raw accelerometer using peak detection + debounce
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
