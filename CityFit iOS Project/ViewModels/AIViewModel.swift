import Foundation
import CoreLocation

/// All AI backend interactions (chat, route generation, photo verification).
/// Every call degrades gracefully when the backend is offline.
@MainActor
final class AIViewModel: ObservableObject {

    // Chat
    @Published var chatMessages: [ChatMessage] = [
        ChatMessage(role: .assistant,
                    text: "Hey! I'm your CityFit coach 💪 Ask me anything about missions, training, or staying motivated!")
    ]
    @Published var isChatLoading = false

    // Route
    @Published var routeResult: RouteResponse?
    @Published var isGeneratingRoute = false
    @Published var routeError: String?

    // MARK: - Chat

    func sendChat(_ text: String, profile: UserProfile?, activeMission: Mission?, stepsToday: Int, missionsCompleted: Int = 0) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        chatMessages.append(ChatMessage(role: .user, text: trimmed))
        isChatLoading = true
        defer { isChatLoading = false }

        let request = ChatRequest(user_message: trimmed,
                                  level: profile?.level ?? 1,
                                  exp: profile?.currentEXP ?? 0,
                                  steps_today: stepsToday,
                                  active_mission: activeMission?.title ?? "none",
                                  streak: profile?.streak ?? 0,
                                  missions_completed: missionsCompleted)
        do {
            let reply = try await AIService.chat(request)
            chatMessages.append(ChatMessage(role: .assistant, text: reply))
        } catch {
            // User sees a friendly message; the developer sees the real cause in the console.
            print("⚠️ AI chat failed: \(error.localizedDescription)")
            chatMessages.append(ChatMessage(role: .assistant,
                                            text: "I'm offline right now 😴 — but keep moving! Walking any mission still earns you EXP."))
        }
    }

    // MARK: - Route generation

    func generateRoute(from location: CLLocationCoordinate2D,
                       level: Int,
                       missions: [Mission],
                       preferredDistance: Double = 2000) async {
        isGeneratingRoute = true
        routeError = nil
        defer { isGeneratingRoute = false }

        let pins = missions.compactMap { mission -> RouteRequest.Pin? in
            guard let coordinate = mission.coordinate else { return nil }
            return RouteRequest.Pin(id: mission.id,
                                    title: mission.title,
                                    lat: coordinate.latitude,
                                    lng: coordinate.longitude,
                                    exp: mission.expReward)
        }
        let request = RouteRequest(current_lat: location.latitude,
                                   current_lng: location.longitude,
                                   level: level,
                                   mission_pins: pins,
                                   preferred_distance: preferredDistance)
        do {
            routeResult = try await AIService.generateRoute(request)
        } catch {
            print("⚠️ AI route generation failed: \(error.localizedDescription)")
            routeError = error.localizedDescription
        }
    }

    // MARK: - Photo verification (legacy cloud path — UNUSED)
    // Photo missions now verify fully on-device via VisionService (DeepSeek is
    // text-only and can't accept images). Kept only so the /verify-photo
    // backend endpoint has a client if a vision-capable provider is added later.

    func verifyPhoto(base64: String, target: String, userID: String) async -> VerifyPhotoResponse? {
        let request = VerifyPhotoRequest(image_base64: base64,
                                         target_object: target,
                                         user_id: userID)
        return try? await AIService.verifyPhoto(request)
    }
}
