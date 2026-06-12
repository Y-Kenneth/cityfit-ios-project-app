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
