import Foundation

struct LeaderboardEntry: Identifiable {
    let rank: Int
    let username: String
    let exp: Int
    let level: Int
    let character: CharacterType
    var gender: Gender = .male
    var weightKg: Double = 70
    var heightCm: Double = 170
    var restingHeartRate: Int? = nil
    var activeEnergyKcal: Double? = nil
    var streak: Int = 0
    var totalSteps: Int = 0

    var id: Int { rank }

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
}
