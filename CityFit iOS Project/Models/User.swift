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
    var joinedCommunityIds: [String]

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
                    streak: 0,
                    joinedCommunityIds: [])
    }

    init(id: String, username: String, character: CharacterType, level: Int, currentEXP: Int,
         totalSteps: Int, missionsCompleted: Int, joinDate: Date, weeklySteps: [Int], streak: Int,
         joinedCommunityIds: [String] = []) {
        self.id = id
        self.username = username
        self.character = character
        self.level = level
        self.currentEXP = currentEXP
        self.totalSteps = totalSteps
        self.missionsCompleted = missionsCompleted
        self.joinDate = joinDate
        self.weeklySteps = weeklySteps
        self.streak = streak
        self.joinedCommunityIds = joinedCommunityIds
    }

    // `joinedCommunityIds` is decoded with a default so older locally-cached
    // profiles (saved before this field existed) still decode instead of
    // failing on a missing key.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        username = try c.decode(String.self, forKey: .username)
        character = try c.decode(CharacterType.self, forKey: .character)
        level = try c.decode(Int.self, forKey: .level)
        currentEXP = try c.decode(Int.self, forKey: .currentEXP)
        totalSteps = try c.decode(Int.self, forKey: .totalSteps)
        missionsCompleted = try c.decode(Int.self, forKey: .missionsCompleted)
        joinDate = try c.decode(Date.self, forKey: .joinDate)
        weeklySteps = try c.decode([Int].self, forKey: .weeklySteps)
        streak = try c.decode(Int.self, forKey: .streak)
        joinedCommunityIds = try c.decodeIfPresent([String].self, forKey: .joinedCommunityIds) ?? []
    }
}

enum CharacterType: String, Codable, CaseIterable {
    case sportsmanM = "sportsman_m"
    case sportsmanF = "sportsman_f"
    case studentF   = "student_f"
    case rabbit     = "rabbit"
    case cyclist    = "cyclist"
    case swimmer    = "swimmer"
    case ninja      = "ninja"
    case robot      = "robot"

    var displayName: String {
        switch self {
        case .sportsmanM: return "Sportsman"
        case .sportsmanF: return "Sportswoman"
        case .studentF:   return "Student"
        case .rabbit:     return "Rabbit"
        case .cyclist:    return "Cyclist"
        case .swimmer:    return "Swimmer"
        case .ninja:      return "Ninja"
        case .robot:      return "Robot"
        }
    }

    var emoji: String {
        switch self {
        case .sportsmanM: return "🏃‍♂️"
        case .sportsmanF: return "🏃‍♀️"
        case .studentF:   return "👩‍🎓"
        case .rabbit:     return "🐰"
        case .cyclist:    return "🚴"
        case .swimmer:    return "🏊"
        case .ninja:      return "🥷"
        case .robot:      return "🤖"
        }
    }

    /// Drop a standing-pose image into Assets.xcassets named exactly this
    /// (e.g. "character_cyclist") and CharacterPortraitView picks it up
    /// automatically — same auto-detect pattern as VisionService's trained model.
    var imageName: String { "character_\(rawValue)" }
}
