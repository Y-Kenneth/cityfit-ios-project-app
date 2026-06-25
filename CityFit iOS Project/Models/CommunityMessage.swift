import Foundation

/// One message in a community's group chat. `senderCharacter` is captured at
/// send-time (not live-joined from the sender's current profile) so old
/// messages keep showing the avatar the sender had when they sent it — same
/// snapshot pattern as LeaderboardEntry.character.
struct CommunityMessage: Identifiable, Equatable {
    let id: String
    let senderId: String
    let senderUsername: String
    let senderCharacter: CharacterType
    let text: String
    let sentAt: Date
}
