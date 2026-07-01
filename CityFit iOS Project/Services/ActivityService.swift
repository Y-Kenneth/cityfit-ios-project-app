import Foundation
import CoreMotion

// Detects if user is walking, running, or stationary using accelerometer data.
// Uses a simple magnitude heuristic over a rolling window of samples.
final class ActivityService: ObservableObject {
    enum Activity: String {
        case walking, running, stationary

        var label: String {
            switch self {
            case .walking:    return "Walking"
            case .running:    return "Running"
            case .stationary: return "Stationary"
            }
        }

        var multiplier: Double {
            switch self {
            case .running:    return Constants.EXP.runningMultiplier
            case .walking:    return Constants.EXP.walkingMultiplier
            case .stationary: return Constants.EXP.stationaryMultiplier
            }
        }
    }

    @Published var activity: Activity = .stationary
    @Published var expMultiplier: Double = Constants.EXP.stationaryMultiplier

    private let motionManager = CMMotionManager()
    private var classifyTimer: Timer?

    private let windowSize = 50
    private var samples: [(accel: CMAcceleration, gyro: CMRotationRate)] = []

    func start() {
        #if targetEnvironment(simulator)
        classifyTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.update(.walking)
        }
        #else
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.samples.append((motion.userAcceleration, motion.rotationRate))
            if self.samples.count > self.windowSize {
                self.samples.removeFirst(self.samples.count - self.windowSize)
            }
        }
        classifyTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.classify()
        }
        #endif
    }

    func stop() {
        classifyTimer?.invalidate()
        classifyTimer = nil
        motionManager.stopDeviceMotionUpdates()
        samples.removeAll()
        update(.stationary)
    }

    // MARK: - Classification

    private func classify() {
        guard samples.count >= windowSize else { return }
        update(classifyWithHeuristic())
    }

    // classify based on average acceleration magnitude across the sample window
    private func classifyWithHeuristic() -> Activity {
        let magnitudes = samples.suffix(windowSize).map {
            sqrt($0.accel.x * $0.accel.x + $0.accel.y * $0.accel.y + $0.accel.z * $0.accel.z)
        }
        let mean = magnitudes.reduce(0, +) / Double(magnitudes.count)
        switch mean {
        case ..<0.05:  return .stationary
        case ..<0.45:  return .walking
        default:       return .running
        }
    }

    private func update(_ newActivity: Activity) {
        DispatchQueue.main.async {
            let previous = self.activity
            self.activity = newActivity
            self.expMultiplier = newActivity.multiplier
            self.announce(from: previous, to: newActivity)
        }
    }

    // only announce when starting/stopping a run, not every small change
    private func announce(from previous: Activity, to current: Activity) {
        guard previous != current else { return }
        switch current {
        case .running:
            VoiceCoachService.shared.speak("Nice, you're running now — double EXP.")
        case .walking where previous == .running:
            VoiceCoachService.shared.speak("Pace dropped to walking — back to normal EXP.")
        default:
            break
        }
    }
}
