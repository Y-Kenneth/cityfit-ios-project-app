import Foundation
import CoreLocation

struct Mission: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var type: MissionType
    var targetValue: Double
    var currentValue: Double
    var expReward: Int
    var difficulty: Difficulty
    var status: MissionStatus
    var timeLimit: Int?          // minutes
    var targetObject: String?    // for .photo type: "bottle", "bicycle", etc.
    var latitude: Double?        // optional pin location
    var longitude: Double?
    var cooldownUntil: Date?     // nil = no cooldown active

    // CLLocationCoordinate2D is not Codable, so the pin is stored as lat/lng
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }

    var isComplete: Bool { currentValue >= targetValue }

    init(id: String, title: String, description: String, type: MissionType,
         targetValue: Double, currentValue: Double, expReward: Int,
         difficulty: Difficulty, status: MissionStatus,
         timeLimit: Int? = nil, targetObject: String? = nil,
         coordinate: CLLocationCoordinate2D? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.expReward = expReward
        self.difficulty = difficulty
        self.status = status
        self.timeLimit = timeLimit
        self.targetObject = targetObject
        self.latitude = coordinate?.latitude
        self.longitude = coordinate?.longitude
    }
}

enum MissionType: String, Codable {
    case steps, distance, photo

    var icon: String {
        switch self {
        case .steps:    return "figure.walk"
        case .distance: return "map"
        case .photo:    return "camera.fill"
        }
    }

    var unit: String {
        switch self {
        case .steps:    return "steps"
        case .distance: return "m"
        case .photo:    return "found"
        }
    }
}

enum Difficulty: String, Codable {
    case easy, medium, hard

    var label: String { rawValue.capitalized }
}

enum MissionStatus: String, Codable {
    case available, active, completed, failed, cooldown
}
