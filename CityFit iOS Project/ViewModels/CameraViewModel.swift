import Foundation
import SwiftUI

/// Drives the two-tier photo mission detection:
/// Tier 1 — Apple Vision live classification, on-device (auto-complete at high
///          confidence). Uses VisionService, which automatically prefers a
///          trained CreateML model when bundled.
/// Tier 2 — the captured frame is sent to the backend Vision Crew (DeepSeek
///          Vision + the Object Detection Specialist agent) when the user taps
///          "Snap" on a medium-confidence hit. Falls back to a stricter
///          on-device re-check if the backend is unreachable, so the feature
///          still works offline.
final class CameraViewModel: ObservableObject {

    enum DetectionState: Equatable {
        case scanning
        case possible      // medium confidence — Snap button shown
        case detected      // confirmed (Tier 1 auto, or Tier 2 backend/on-device)
        case verifying     // Tier 2 backend round-trip in flight
        case rejected      // Tier 2 said no
    }

    @Published var state: DetectionState = .scanning
    @Published var statusMessage: String?

    let camera = CameraService()
    private let vision = VisionService()

    private(set) var targetObject = ""
    private var cooldownUntil = Date.distantPast

    /// When the current `state` was entered — used to tell a sustained "not
    /// finding it" from a one-off noisy frame before speaking a voice hint.
    private var stateEnteredAt = Date()
    private var voiceCooldownUntil = Date.distantPast

    /// Wired to MissionViewModel.incrementPhotoProgress by the view.
    var onObjectFound: (() -> Void)?

    func start(target: String) {
        targetObject = target
        stateEnteredAt = Date()
        camera.frameHandler = { [weak self] buffer in
            guard let self else { return }
            // VisionService calls back on the main queue
            self.vision.detect(target: target, in: buffer) { confidence in
                self.handle(confidence: confidence)
            }
        }
        camera.start()
    }

    func stop() {
        camera.frameHandler = nil
        camera.stop()
    }

    // MARK: - Tier 1: Apple Vision confidence handler

    func handle(confidence: Float) {
        guard Date() >= cooldownUntil, state != .verifying else { return }
        let previousState = state
        switch confidence {
        case 0.85...1.0:
            state = .detected
            statusMessage = "✅ \(targetObject.capitalized) detected!"
            onObjectFound?()        // auto-complete, no Groq call needed
            beginCooldown(4)
        case 0.50..<0.85:
            state = .possible
            statusMessage = "⚠️ Possible \(targetObject) detected"
        default:
            state = .scanning
            statusMessage = nil
        }
        if state != previousState { stateEnteredAt = Date() }
        announceFramingHintIfNeeded()
    }

    /// Speaks a framing hint once a confidence band has been sustained for a
    /// bit — a one-off noisy frame shouldn't trigger a voice line, but a real
    /// "can't quite see it" should. Confidence here has no notion of distance
    /// (it's a single whole-frame score, not a bounding box), so this is a
    /// best-effort proxy: sustained medium confidence usually means the object
    /// is there but small/angled/partial; sustained zero match usually means
    /// it's just not in frame.
    private func announceFramingHintIfNeeded() {
        guard Date() >= voiceCooldownUntil else { return }
        let sustained = Date().timeIntervalSince(stateEnteredAt)
        switch state {
        case .possible where sustained >= 1.5:
            VoiceCoachService.shared.speak("Try getting a little closer.")
            voiceCooldownUntil = Date().addingTimeInterval(4)
        case .scanning where sustained >= 4:
            VoiceCoachService.shared.speak("Point the camera at a \(targetObject).")
            voiceCooldownUntil = Date().addingTimeInterval(6)
        default:
            break
        }
    }

    // MARK: - Tier 2: Vision Crew (backend) verification, on-device fallback

    /// Confidence the captured frame must clear to confirm a "Snap" when the
    /// backend Vision Crew is unreachable (degrade gracefully, per CLAUDE.md).
    private let snapConfirmThreshold: Float = 0.65

    /// Medium-confidence "Snap" goes to the backend Vision Crew (DeepSeek
    /// Vision describes the photo, the Object Detection Specialist agent
    /// gives a strict verdict) for a stronger check than the live Tier-1
    /// scan. Falls back to a stricter on-device re-check if the backend is
    /// unreachable, so the feature still works offline.
    @MainActor
    func snap(userID: String, aiViewModel: AIViewModel) async {
        guard camera.latestPixelBuffer() != nil, let imageBase64 = camera.snapBase64() else {
            statusMessage = "Couldn't capture a photo — try again"
            return
        }
        state = .verifying
        statusMessage = "Verifying…"

        let target = targetObject
        do {
            let response = try await AIService.verifyPhoto(
                VerifyPhotoRequest(image_base64: imageBase64, target_object: target, user_id: userID))
            if response.detected {
                state = .detected
                statusMessage = "✅ \(target.capitalized) confirmed!"
                onObjectFound?()
                beginCooldown(4)
            } else {
                state = .rejected
                statusMessage = "Not quite — try getting closer"
                beginCooldown(2)
            }
        } catch {
            await fallbackOnDeviceSnap(target: target)
        }
    }

    /// Used only when the backend Vision Crew can't be reached.
    private func fallbackOnDeviceSnap(target: String) async {
        guard let buffer = camera.latestPixelBuffer() else {
            state = .rejected
            statusMessage = "Not quite — try getting closer"
            beginCooldown(2)
            return
        }
        let confidence: Float = await withCheckedContinuation { continuation in
            vision.detect(target: target, in: buffer) { value in
                continuation.resume(returning: value)
            }
        }
        if confidence >= snapConfirmThreshold {
            state = .detected
            statusMessage = "✅ \(target.capitalized) confirmed!"
            onObjectFound?()
            beginCooldown(4)
        } else {
            state = .rejected
            statusMessage = "Not quite — try getting closer"
            beginCooldown(2)
        }
    }

    /// Simulator helper — the camera doesn't exist there, so the demo
    /// button drives the same state machine.
    func simulateDetection(confidence: Float) {
        handle(confidence: confidence)
    }

    private func beginCooldown(_ seconds: TimeInterval) {
        cooldownUntil = Date().addingTimeInterval(seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            guard let self, self.state != .verifying else { return }
            self.state = .scanning
            self.statusMessage = nil
        }
    }
}
