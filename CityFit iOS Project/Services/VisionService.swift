import Foundation
import Vision
import CoreVideo
import CoreML

// On-device photo detection for missions.
// Uses the trained ImageClassifier.mlmodel if it's bundled in the project.
// Falls back to Apple's built-in image classifier if the model is missing.
final class VisionService {

    // maps mission target names to the actual labels used in the trained model
    private static let synonyms: [String: [String]] = [
        "bottle":   ["bottle", "flask", "jug", "water bottle", "plastic bottle"],
        "bicycle":  ["bicycle", "bike", "cycle", "tandem"],
        "plant":    ["plants", "plant", "flower", "blossom", "bloom", "petal", "rose", "daisy", "tree", "leaf", "shrub", "bush"],
        "chair":    ["chair", "seat", "bench", "stool", "armchair", "sofa"],
        "person":   ["person", "man", "woman", "boy", "girl", "human", "male", "female"],
        "trashbin": ["trash can", "bin", "garbage", "waste bin", "dustbin", "rubbish", "trashbin", "trash bin"],
        "car":      ["car", "vehicle", "automobile", "sedan", "suv", "truck"],
        "computer": ["computer", "laptop", "monitor", "desktop", "notebook computer", "macbook", "pc", "screen"],
        "cat":      ["cat", "kitten", "feline", "tabby"],
    ]

    // nil if no trained model found, will use built-in classifier instead
    private let customModel: VNCoreMLModel?

    init() {
        customModel = Self.loadCustomModel()
    }

    // true if the trained CoreML model loaded successfully
    var isUsingTrainedModel: Bool { customModel != nil }

    // runs classification on a camera frame and returns confidence score 0-1
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

    // finds the highest confidence score from results that match the target keywords
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

    // tries to load the trained model from the app bundle
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
