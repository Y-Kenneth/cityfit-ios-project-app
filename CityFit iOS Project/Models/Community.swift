import Foundation

struct Community: Identifiable {
    let id: String
    let name: String
    let description: String
    let memberCount: Int
    var isJoined: Bool
    let tags: [String]
}
