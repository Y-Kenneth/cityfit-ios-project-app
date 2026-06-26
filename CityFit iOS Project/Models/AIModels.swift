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
    }

    let distance_meters: Double
    let walk: ModeEstimate
    let run: ModeEstimate
    let summary: String
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
