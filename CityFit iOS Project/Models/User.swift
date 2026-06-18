import Foundation

struct UserProfile: Codable {
    var id: String
    var username: String
    var character: CharacterType
    var level: Int
    var currentEXP: Int
    var totalSteps: Int
    var missionsCompleted: Int
    var joinDate: Date
    var weeklySteps: [Int]       // [today, yesterday, ...6 days ago]
    var streak: Int

    static func new(id: String = UUID().uuidString, username: String, character: CharacterType) -> UserProfile {
        UserProfile(id: id,
                    username: username,
                    character: character,
                    level: 1,
                    currentEXP: 0,
                    totalSteps: 0,
                    missionsCompleted: 0,
                    joinDate: Date(),
                    weeklySteps: [0, 0, 0, 0, 0, 0, 0],
                    streak: 0)
    }
}

enum CharacterType: String, Codable, CaseIterable {
    case sportsmanM = "sportsman_m"
    case sportsmanF = "sportsman_f"
    case studentF   = "student_f"
    case rabbit     = "rabbit"

    var displayName: String {
        switch self {
        case .sportsmanM: return "Sportsman"
        case .sportsmanF: return "Sportswoman"
        case .studentF:   return "Student"
        case .rabbit:     return "Rabbit"
        }
    }

    var emoji: String {
        switch self {
        case .sportsmanM: return "🏃‍♂️"
        case .sportsmanF: return "🏃‍♀️"
        case .studentF:   return "👩‍🎓"
        case .rabbit:     return "🐰"
        }
    }
}
