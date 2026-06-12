import Foundation
import Vision
import CoreVideo
import CoreML

/// On-device object detection for photo missions.
///
/// Two-stage model resolution (no code change needed when you train your own):
///   1. If a Core ML model named `ImageClassifier.mlmodelc` is bundled
///      (drag your CreateML-trained `ImageClassifier.mlmodel` into the Xcode
///      project), Vision runs that model.
///   2. Otherwise it falls back to Apple's built-in general image classifier
///      (`VNClassifyImageRequest`), so the feature works today untrained.
///
/// See `CLAUDE.md` → "Training the photo-mission model" for how to train and
/// drop in the model.
final class VisionService {

    /// Synonyms that count as a match for each mission target — used to map a
    /// model's label vocabulary onto our mission targets. Add the exact labels
    /// you trained in CreateML here if they differ from the target word.
    private static let synonyms: [String: [String]] = [
        "bottle":  ["bottle", "flask", "jug", "water bottle"],
        "bicycle": ["bicycle", "bike", "cycle", "tandem"],
        "plant":   ["plant", "tree", "flower", "foliage", "vegetation", "leaf", "shrub", "grass"],
        "bench":   ["bench", "seat"],
    ]

    /// Loaded once. nil means "no trained model bundled — use the built-in."
    private let customModel: VNCoreMLModel?

    init() {
        customModel = Self.loadCustomModel()
    }

    /// Whether a trained CreateML model is in use (vs. the built-in classifier).
    var isUsingTrainedModel: Bool { customModel != nil }

    /// Classifies a camera frame and reports the best confidence (0...1) that
    /// the target object is present.
    func detect(target: String, in pixelBuffer: CVPixelBuffer,
                completion: @escaping (Float) -> Void) {
        let keywords = Self.synonyms[target.lowercased()] ?? [target.lowercased()]

        let request: VNRequest
        if let customModel {
            request = VNCoreMLRequest(model: customModel) { request, _ in
                let best = Self.bestConfidence(in: request.results, matching: keywords)
                DispatchQueue.main.async { completion(best) }
            }
            (request as? VNCoreMLRequest)?.imageCropAndScaleOption = .centerCrop
        } else {
            request = VNClassifyImageRequest { request, _ in
                let best = Self.bestConfidence(in: request.results, matching: keywords)
                DispatchQueue.main.async { completion(best) }
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    // MARK: - Helpers

    /// Best confidence among classification results whose label matches any keyword.
    private static func bestConfidence(in results: [VNObservation]?,
                                       matching keywords: [String]) -> Float {
        let observations = (results as? [VNClassificationObservation]) ?? []
        return observations
            .filter { observation in
                let identifier = observation.identifier.lowercased()
                return keywords.contains { identifier.contains($0) }
            }
            .map(\.confidence)
            .max() ?? 0
    }

    /// Looks for a bundled CreateML image classifier. Returns nil if none is
    /// present (the common case until you train one).
    private static func loadCustomModel() -> VNCoreMLModel? {
        guard let url = Bundle.main.url(forResource: "ImageClassifier", withExtension: "mlmodelc") else {
            return nil
        }
        do {
            let mlModel = try MLModel(contentsOf: url)
            return try VNCoreMLModel(for: mlModel)
        } catch {
            print("⚠️ Found ImageClassifier.mlmodelc but failed to load it: \(error.localizedDescription). Falling back to the built-in classifier.")
            return nil
        }
    }
}
