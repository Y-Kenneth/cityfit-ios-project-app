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
    var gender: Gender
    var weightKg: Double
    var heightCm: Double
    var restingHeartRate: Int?
    var activeEnergyKcal: Double?
    var isHealthKitConnected: Bool

    /// Standard BMI = kg / m². `heightCm` is always > 0 (clamped by the
    /// stepper UI), so no divide-by-zero guard needed here.
    var bmi: Double {
        let heightM = heightCm / 100
        return weightKg / (heightM * heightM)
    }

    var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case ..<25:   return "Normal"
        case ..<30:   return "Overweight"
        default:      return "Obese"
        }
    }

    static func new(id: String = UUID().uuidString, username: String, character: CharacterType,
                     gender: Gender = .male, weightKg: Double = 70, heightCm: Double = 170) -> UserProfile {
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
                    joinedCommunityIds: [],
                    gender: gender,
                    weightKg: weightKg,
                    heightCm: heightCm)
    }

    init(id: String, username: String, character: CharacterType, level: Int, currentEXP: Int,
         totalSteps: Int, missionsCompleted: Int, joinDate: Date, weeklySteps: [Int], streak: Int,
         joinedCommunityIds: [String] = [], gender: Gender = .male, weightKg: Double = 70,
         heightCm: Double = 170, restingHeartRate: Int? = nil, activeEnergyKcal: Double? = nil,
         isHealthKitConnected: Bool = false) {
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
        self.gender = gender
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.restingHeartRate = restingHeartRate
        self.activeEnergyKcal = activeEnergyKcal
        self.isHealthKitConnected = isHealthKitConnected
    }

    // Health fields are decoded with defaults so older locally-cached
    // profiles (saved before these fields existed) still decode instead of
    // failing on a missing key — same pattern as `joinedCommunityIds`.
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
        gender = try c.decodeIfPresent(Gender.self, forKey: .gender) ?? .male
        weightKg = try c.decodeIfPresent(Double.self, forKey: .weightKg) ?? 70
        heightCm = try c.decodeIfPresent(Double.self, forKey: .heightCm) ?? 170
        restingHeartRate = try c.decodeIfPresent(Int.self, forKey: .restingHeartRate)
        activeEnergyKcal = try c.decodeIfPresent(Double.self, forKey: .activeEnergyKcal)
        isHealthKitConnected = try c.decodeIfPresent(Bool.self, forKey: .isHealthKitConnected) ?? false
    }
}

enum Gender: String, Codable, CaseIterable {
    case male, female

    var displayName: String {
        switch self {
        case .male:   return "Male"
        case .female: return "Female"
        }
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
