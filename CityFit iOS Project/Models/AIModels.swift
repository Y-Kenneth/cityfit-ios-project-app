import Foundation
import CoreLocation

// MARK: - Chat

struct ChatMessage: Identifiable {
    enum Role { case user, assistant }

    let id = UUID()
    let role: Role
    let text: String
}

struct ChatRequest: Encodable {
    let user_message: String
    let level: Int
    let exp: Int
    let steps_today: Int
    let active_mission: String
    let streak: Int
    let missions_completed: Int
}

struct ChatResponse: Decodable {
    let response: String
}

// MARK: - Route

struct RouteRequest: Encodable {
    struct Pin: Encodable {
        let id: String
        let title: String
        let lat: Double
        let lng: Double
        let exp: Int
    }

    let current_lat: Double
    let current_lng: Double
    let level: Int
    let mission_pins: [Pin]
    let preferred_distance: Double
}

struct RouteResponse: Decodable {
    struct Waypoint: Decodable {
        let lat: Double
        let lng: Double
        let title: String

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
    }

    let waypoints: [Waypoint]
    let calories: Int
    let exp: Int
    let minutes: Int
    let summary: String
}

// Allows presenting the route via .fullScreenCover(item:). The waypoint
// sequence + summary uniquely identify a generated route for the UI.
extension RouteResponse: Identifiable {
    var id: String {
        waypoints.map { "\($0.lat),\($0.lng)" }.joined(separator: "|") + summary
    }
}

// MARK: - Trip (point-to-point walk/run estimate)

struct TripRequest: Encodable {
    let origin_lat: Double
    let origin_lng: Double
    let destination_lat: Double
    let destination_lng: Double
    let distance_meters: Double
    let level: Int
    let weight_kg: Double
}

struct TripResponse: Decodable {
    struct ModeEstimate: Decodable {
        let steps: Int
        let minutes: Int
        let calories: Int

        init(steps: Int, minutes: Int, calories: Int) {
            self.steps = steps
            self.minutes = minutes
            self.calories = calories
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            steps = c.flexibleInt(forKey: .steps)
            minutes = c.flexibleInt(forKey: .minutes)
            calories = c.flexibleInt(forKey: .calories)
        }

        private enum CodingKeys: String, CodingKey { case steps, minutes, calories }
    }

    let distance_meters: Double
    let walk: ModeEstimate
    let run: ModeEstimate
    let summary: String

    init(distance_meters: Double, walk: ModeEstimate, run: ModeEstimate, summary: String) {
        self.distance_meters = distance_meters
        self.walk = walk
        self.run = run
        self.summary = summary
    }

    // Tolerant decoding: the Pace Estimator agent returns steps/minutes/calories
    // as floats (MET arithmetic → 32.4) or quoted strings, which strict `Int`
    // decoding rejected — that decode failure surfaced in the app as the
    // misleading "unexpected response (HTTP 200)". Accept Int/Double/String for
    // every number, and fall back to safe defaults for any missing field, so a
    // 200 from the backend always yields a usable result.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        distance_meters = c.flexibleDouble(forKey: .distance_meters)
        walk = (try? c.decode(ModeEstimate.self, forKey: .walk))
            ?? ModeEstimate(steps: 0, minutes: 0, calories: 0)
        run = (try? c.decode(ModeEstimate.self, forKey: .run))
            ?? ModeEstimate(steps: 0, minutes: 0, calories: 0)
        summary = (try? c.decode(String.self, forKey: .summary)) ?? "Your trip is ready!"
    }

    private enum CodingKeys: String, CodingKey { case distance_meters, walk, run, summary }
}

/// Number fields from the AI backend can arrive as JSON int, float, or quoted
/// string depending on how the LLM formats them. These coerce any of those into
/// the Swift type we need instead of throwing on a type mismatch.
private extension KeyedDecodingContainer {
    func flexibleInt(forKey key: Key) -> Int {
        if let value = try? decode(Int.self, forKey: key) { return value }
        if let value = try? decode(Double.self, forKey: key) { return Int(value.rounded()) }
        if let value = try? decode(String.self, forKey: key), let number = Double(value) {
            return Int(number.rounded())
        }
        return 0
    }

    func flexibleDouble(forKey key: Key) -> Double {
        if let value = try? decode(Double.self, forKey: key) { return value }
        if let value = try? decode(Int.self, forKey: key) { return Double(value) }
        if let value = try? decode(String.self, forKey: key), let number = Double(value) {
            return number
        }
        return 0
    }
}

// Allows presenting the trip result via .sheet(item:).
extension TripResponse: Identifiable {
    var id: String { "\(distance_meters)|\(summary)" }
}

// MARK: - Photo Verification

struct VerifyPhotoRequest: Encodable {
    let image_base64: String
    let target_object: String
    let user_id: String
}

struct VerifyPhotoResponse: Decodable {
    let detected: Bool
    let description: String
    let confidence: String
}
