import Foundation
import CoreMotion
import CoreML

/// Classifies the user's current activity (walking / running / stationary)
/// from accelerometer + gyroscope data and exposes the EXP multiplier.
///
/// Uses the custom CreateML ActivityClassifier model when it is bundled
/// (Phase 2 — drag ActivityClassifier.mlmodel into the project). Until then
/// it falls back to a motion-magnitude heuristic so the feature works end to end.
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
    @Published var usesCoreMLModel = false

    private let motionManager = CMMotionManager()
    private var classifyTimer: Timer?

    // Rolling window of recent sensor samples (CreateML prediction window = 50)
    private let windowSize = 50
    private var samples: [(accel: CMAcceleration, gyro: CMRotationRate)] = []

    private var model: MLModel? = {
        guard let url = Bundle.main.url(forResource: "ActivityClassifier", withExtension: "mlmodelc") else {
            return nil
        }
        return try? MLModel(contentsOf: url)
    }()

    func start() {
        usesCoreMLModel = model != nil

        #if targetEnvironment(simulator)
        // No motion sensors on the simulator — pretend the user is walking
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
        if let model, let predicted = classifyWithModel(model) {
            update(predicted)
        } else {
            update(classifyWithHeuristic())
        }
    }

    /// Dynamic CoreML prediction matching the CreateML Activity Classification
    /// template (inputs named after the CSV columns, plus a stateIn array).
    private func classifyWithModel(_ model: MLModel) -> Activity? {
        let window = samples.suffix(windowSize)
        let channels: [String: [Double]] = [
            "accel_x": window.map { $0.accel.x },
            "accel_y": window.map { $0.accel.y },
            "accel_z": window.map { $0.accel.z },
            "gyro_x":  window.map { $0.gyro.x },
            "gyro_y":  window.map { $0.gyro.y },
            "gyro_z":  window.map { $0.gyro.z },
        ]
        do {
            var features: [String: MLFeatureValue] = [:]
            for (name, description) in model.modelDescription.inputDescriptionsByName {
                guard let constraint = description.multiArrayConstraint else { continue }
                if let values = channels[name] {
                    let array = try MLMultiArray(shape: [NSNumber(value: windowSize)], dataType: .double)
                    for (index, value) in values.enumerated() {
                        array[index] = NSNumber(value: value)
                    }
                    features[name] = MLFeatureValue(multiArray: array)
                } else {
                    // stateIn — pass zeros (stateless prediction)
                    let array = try MLMultiArray(shape: constraint.shape, dataType: .double)
                    features[name] = MLFeatureValue(multiArray: array)
                }
            }
            let provider = try MLDictionaryFeatureProvider(dictionary: features)
            let output = try model.prediction(from: provider)
            guard let label = output.featureValue(for: "label")?.stringValue else { return nil }
            return Activity(rawValue: label)
        } catch {
            return nil
        }
    }

    /// Fallback when no trained model is bundled: average user-acceleration
    /// magnitude over the window separates still / walk / run well enough.
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
            self.activity = newActivity
            self.expMultiplier = newActivity.multiplier
        }
    }
}
