import Foundation
import SwiftUI

// Handles photo mission detection.
// On-device runs first (Tier 1). If confidence is too low, user taps Snap to
// send the photo to the backend for a stronger check (Tier 2).
// Falls back to on-device again if backend is not reachable.
final class CameraViewModel: ObservableObject {

    enum DetectionState: Equatable {
        case scanning
        case possible      // not sure yet, show Snap button
        case detected      // mission complete
        case verifying     // waiting for backend response
        case rejected      // backend said no
    }

    @Published var state: DetectionState = .scanning
    @Published var statusMessage: String?

    let camera = CameraService()
    private let vision = VisionService()

    private(set) var targetObject = ""
    private var cooldownUntil = Date.distantPast

    // tracks how long we've been in the current state, for voice hints
    private var stateEnteredAt = Date()
    private var voiceCooldownUntil = Date.distantPast

    // set by the view to trigger mission progress on detection
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
            onObjectFound?()        // high confidence, auto-complete
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

    // gives the user a voice tip if the same low-confidence state lasts too long
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

    // MARK: - Snap (backend check)

    // minimum confidence needed to confirm on-device when backend is offline
    private let snapConfirmThreshold: Float = 0.65

    // sends photo to backend for a stronger check. falls back to on-device if backend is down.
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

    // runs on-device check only when backend is not reachable
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

    // for testing on Simulator since there's no real camera there
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
