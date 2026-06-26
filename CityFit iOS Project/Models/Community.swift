import Foundation

struct Community: Identifiable {
    let id: String
    let name: String
    let description: String
    let longDescription: String
    let imageName: String?
    let tags: [String]
    var memberCount: Int
    var isJoined: Bool
}
