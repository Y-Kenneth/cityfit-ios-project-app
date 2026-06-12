import Foundation

struct EXPCalculator {
    static func expRequired(forLevel level: Int) -> Int {
        level * Constants.EXP.perLevel
    }

    static func level(forEXP exp: Int) -> Int {
        max(1, exp / Constants.EXP.perLevel)
    }

    static func progress(currentEXP: Int) -> Double {
        let levelEXP = currentEXP % Constants.EXP.perLevel
        return Double(levelEXP) / Double(Constants.EXP.perLevel)
    }
}
