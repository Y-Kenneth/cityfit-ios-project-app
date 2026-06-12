import Foundation
import Vision
import CoreVideo

/// Tier 1 of the two-tier detection system: on-device Apple Vision
/// image classification, run continuously on camera frames.
final class VisionService {

    /// Vision classification labels that count as a match for each mission target.
    private static let synonyms: [String: [String]] = [
        "bottle":  ["bottle", "flask", "jug"],
        "bicycle": ["bicycle", "bike", "cycle", "tandem"],
        "plant":   ["plant", "tree", "flower", "foliage", "vegetation", "leaf", "shrub", "grass"],
        "bench":   ["bench", "seat"],
    ]

    /// Classifies a camera frame and reports the best confidence for the target object (0...1).
    func detect(target: String, in pixelBuffer: CVPixelBuffer,
                completion: @escaping (Float) -> Void) {
        let keywords = Self.synonyms[target.lowercased()] ?? [target.lowercased()]
        let request = VNClassifyImageRequest { request, _ in
            let observations = (request.results as? [VNClassificationObservation]) ?? []
            let best = observations
                .filter { observation in
                    let identifier = observation.identifier.lowercased()
                    return keywords.contains { identifier.contains($0) }
                }
                .map(\.confidence)
                .max() ?? 0
            DispatchQueue.main.async { completion(best) }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
