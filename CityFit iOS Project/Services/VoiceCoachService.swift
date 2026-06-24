import Foundation
import AVFoundation

/// Speaks short coaching callouts (activity changes, mission/route progress,
/// camera framing hints) during a walk/run. On-device only — AVSpeechSynthesizer
/// needs no network access and no extra Info.plist permission.
final class VoiceCoachService: NSObject {
    static let shared = VoiceCoachService()

    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenAt = Date.distantPast
    private let minInterval: TimeInterval = 3

    private override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers, .duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    /// For routine callouts (progress milestones, activity changes). Skipped if
    /// something is already being spoken or the cooldown window hasn't passed,
    /// so callouts can't pile up or talk over each other.
    func speak(_ text: String) {
        guard !synthesizer.isSpeaking, Date().timeIntervalSince(lastSpokenAt) >= minInterval else { return }
        lastSpokenAt = Date()
        enqueue(text)
    }

    /// For high-priority events (level up, mission/route complete) that should
    /// never be skipped — interrupts any in-progress utterance.
    func speakNow(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }
        lastSpokenAt = Date()
        enqueue(text)
    }

    private func enqueue(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        synthesizer.speak(utterance)
    }
}
