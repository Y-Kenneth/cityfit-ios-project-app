import Foundation

struct Community: Identifiable {
    let id: String
    let name: String
    let description: String
    let tags: [String]
    var memberCount: Int
    var isJoined: Bool
}
