import Foundation

struct LeaderboardEntry: Identifiable {
    let rank: Int
    let username: String
    let exp: Int
    let level: Int
    let character: CharacterType

    var id: Int { rank }
}
