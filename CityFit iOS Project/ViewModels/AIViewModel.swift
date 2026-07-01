import Foundation
import CoreLocation

// Handles chat, route, trip, and photo verification calls to the backend.
// All functions fail gracefully when the backend is not available.
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

    // Trip (point-to-point walk/run estimate)
    @Published var tripResult: TripResponse?
    @Published var isPlanningTripRequest = false
    @Published var tripError: String?

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
            // show friendly message to user, log real error to console
            print("⚠️ AI chat failed: \(error.localizedDescription)")
            chatMessages.append(ChatMessage(role: .assistant,
                                            text: "I'm offline right now 😴 — but keep moving! Walking any mission still earns you EXP."))
        }
    }

    // MARK: - Route generation

    func generateRoute(from location: CLLocationCoordinate2D,
                       level: Int,
                       missions: [Mission],
                       landmarkPins: [RouteRequest.Pin] = [],
                       preferredDistance: Double = 2000) async {
        isGeneratingRoute = true
        routeError = nil
        defer { isGeneratingRoute = false }

        let missionPins = missions.compactMap { mission -> RouteRequest.Pin? in
            guard let coordinate = mission.coordinate else { return nil }
            return RouteRequest.Pin(id: mission.id,
                                    title: mission.title,
                                    lat: coordinate.latitude,
                                    lng: coordinate.longitude,
                                    exp: mission.expReward)
        }
        // shuffle so the route picks different pins each time instead of always the same ones
        let candidatePins = (missionPins + landmarkPins).shuffled()
        let request = RouteRequest(current_lat: location.latitude,
                                   current_lng: location.longitude,
                                   level: level,
                                   mission_pins: candidatePins,
                                   preferred_distance: preferredDistance)
        do {
            routeResult = try await AIService.generateRoute(request)
        } catch {
            print("⚠️ AI route generation failed: \(error.localizedDescription)")
            routeError = error.localizedDescription
        }
    }

    // MARK: - Trip planning (point-to-point walk/run estimate)

    func planTrip(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D,
                 distanceMeters: Double, level: Int, weightKg: Double) async {
        isPlanningTripRequest = true
        tripError = nil
        defer { isPlanningTripRequest = false }

        let request = TripRequest(origin_lat: origin.latitude,
                                  origin_lng: origin.longitude,
                                  destination_lat: destination.latitude,
                                  destination_lng: destination.longitude,
                                  distance_meters: distanceMeters,
                                  level: level,
                                  weight_kg: weightKg)
        do {
            tripResult = try await AIService.planTrip(request)
        } catch {
            print("⚠️ AI trip planning failed: \(error.localizedDescription)")
            tripError = error.localizedDescription
        }
    }

    // MARK: - Photo verification
    // CameraViewModel.snap() calls AIService directly so it can handle the fallback.
    // This is a convenience wrapper in case other screens need it later.

    func verifyPhoto(base64: String, target: String, userID: String) async -> VerifyPhotoResponse? {
        let request = VerifyPhotoRequest(image_base64: base64,
                                         target_object: target,
                                         user_id: userID)
        return try? await AIService.verifyPhoto(request)
    }
}
