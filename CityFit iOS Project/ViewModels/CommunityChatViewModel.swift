import Foundation
import FirebaseFirestore

/// Owns the live Firestore listener for one community's group chat. The
/// caller (CommunityChatView) MUST call `stop()` from `.onDisappear` — mirrors
/// RouteNavigationViewModel's start()/stop() lifecycle pattern. Failing to
/// call stop() leaks the listener: it keeps streaming reads from Firestore
/// for the lifetime of the process, even after the chat screen closes.
@MainActor
final class CommunityChatViewModel: ObservableObject {
    @Published private(set) var messages: [CommunityMessage] = []
    @Published var draftText: String = ""

    private let communityId: String
    private let senderId: String
    private let senderUsername: String
    private let senderCharacter: CharacterType
    private var listener: ListenerRegistration?

    init(communityId: String, senderId: String, senderUsername: String, senderCharacter: CharacterType) {
        self.communityId = communityId
        self.senderId = senderId
        self.senderUsername = senderUsername
        self.senderCharacter = senderCharacter
    }

    func start() {
        guard listener == nil else { return }
        listener = FirestoreService.shared.listenToMessages(communityId: communityId) { [weak self] messages in
            self?.messages = messages
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func send() {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draftText = ""
        Task {
            do {
                try await FirestoreService.shared.sendMessage(
                    communityId: communityId, senderId: senderId,
                    senderUsername: senderUsername, senderCharacter: senderCharacter, text: text)
            } catch {
                print("⚠️ CommunityChatViewModel: send failed — \(error.localizedDescription)")
                draftText = text
            }
        }
    }

    deinit {
        listener?.remove()
    }
}
