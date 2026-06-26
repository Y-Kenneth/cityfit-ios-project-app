import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - User Profile

    func saveUserProfile(_ profile: UserProfile) async throws {
        var data: [String: Any] = [
            "id": profile.id,
            "username": profile.username,
            "character": profile.character.rawValue,
            "level": profile.level,
            "currentEXP": profile.currentEXP,
            "totalSteps": profile.totalSteps,
            "missionsCompleted": profile.missionsCompleted,
            "joinDate": Timestamp(date: profile.joinDate),
            "weeklySteps": profile.weeklySteps,
            "streak": profile.streak,
            "joinedCommunityIds": profile.joinedCommunityIds,
            "gender": profile.gender.rawValue,
            "weightKg": profile.weightKg,
            "heightCm": profile.heightCm,
            "isHealthKitConnected": profile.isHealthKitConnected
        ]
        data["restingHeartRate"] = profile.restingHeartRate
        data["activeEnergyKcal"] = profile.activeEnergyKcal
        try await db.collection("users").document(profile.id).setData(data, merge: true)
    }

    func fetchUserProfile(uid: String) async throws -> UserProfile? {
        let doc = try await db.collection("users").document(uid).getDocument()
        guard let d = doc.data() else { return nil }

        let character = CharacterType(rawValue: d["character"] as? String ?? "") ?? .sportsmanM
        let gender = Gender(rawValue: d["gender"] as? String ?? "") ?? .male
        let joinDate = (d["joinDate"] as? Timestamp)?.dateValue() ?? Date()

        return UserProfile(
            id: d["id"] as? String ?? uid,
            username: d["username"] as? String ?? "",
            character: character,
            level: d["level"] as? Int ?? 1,
            currentEXP: d["currentEXP"] as? Int ?? 0,
            totalSteps: d["totalSteps"] as? Int ?? 0,
            missionsCompleted: d["missionsCompleted"] as? Int ?? 0,
            joinDate: joinDate,
            weeklySteps: d["weeklySteps"] as? [Int] ?? [0, 0, 0, 0, 0, 0, 0],
            streak: d["streak"] as? Int ?? 0,
            joinedCommunityIds: d["joinedCommunityIds"] as? [String] ?? [],
            gender: gender,
            weightKg: d["weightKg"] as? Double ?? 70,
            heightCm: d["heightCm"] as? Double ?? 170,
            restingHeartRate: d["restingHeartRate"] as? Int,
            activeEnergyKcal: d["activeEnergyKcal"] as? Double,
            isHealthKitConnected: d["isHealthKitConnected"] as? Bool ?? false
        )
    }

    // MARK: - Leaderboard

    func updateLeaderboardEntry(uid: String, username: String, xp: Int, level: Int) async throws {
        let data: [String: Any] = [
            "uid": uid,
            "username": username,
            "xp": xp,
            "level": level,
            "updatedAt": Timestamp(date: Date())
        ]
        try await db.collection("leaderboard").document(uid).setData(data, merge: true)
    }

    // MARK: - Community Chat

    /// Starts a live listener on a community's chat, capped to the most recent
    /// 200 messages (oldest-first for display). The caller MUST hold the
    /// returned registration and call `.remove()` when done (e.g. ViewModel
    /// stop()) — letting it fall out of scope without removing it leaks the
    /// listener and keeps streaming reads indefinitely.
    func listenToMessages(
        communityId: String,
        onChange: @escaping ([CommunityMessage]) -> Void
    ) -> ListenerRegistration {
        db.collection("communities").document(communityId).collection("messages")
            .order(by: "sentAt", descending: true)
            .limit(to: 200)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    if let error {
                        print("⚠️ FirestoreService: chat listener error — \(error.localizedDescription)")
                    }
                    return
                }
                let messages: [CommunityMessage] = documents.compactMap { doc in
                    let d = doc.data()
                    guard
                        let senderId = d["senderId"] as? String,
                        let senderUsername = d["senderUsername"] as? String,
                        let characterRaw = d["senderCharacter"] as? String,
                        let character = CharacterType(rawValue: characterRaw),
                        let text = d["text"] as? String
                    else { return nil }
                    let sentAt = (d["sentAt"] as? Timestamp)?.dateValue() ?? Date()
                    return CommunityMessage(id: doc.documentID, senderId: senderId,
                                             senderUsername: senderUsername,
                                             senderCharacter: character, text: text, sentAt: sentAt)
                }
                // Query is newest-first (required for `.limit` to keep the most
                // recent 200, not the oldest 200) — reverse for chronological
                // top-to-bottom display.
                onChange(messages.reversed())
            }
    }

    func sendMessage(communityId: String, senderId: String, senderUsername: String,
                      senderCharacter: CharacterType, text: String) async throws {
        let data: [String: Any] = [
            "senderId": senderId,
            "senderUsername": senderUsername,
            "senderCharacter": senderCharacter.rawValue,
            "text": text,
            "sentAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("communities").document(communityId)
            .collection("messages").addDocument(data: data)
    }

    /// Seeds a community's chat with `MockData.seedMessages` the first time
    /// anyone joins it, so the group chat never opens empty during testing.
    /// Guarded by a single-document existence check (cheap: limit(1) read) —
    /// safe to call on every join, since it's a no-op once any message
    /// exists, including a real one a user sent.
    func seedMockMessagesIfEmpty(communityId: String) async {
        let messagesRef = db.collection("communities").document(communityId).collection("messages")
        do {
            let existing = try await messagesRef.limit(to: 1).getDocuments()
            guard existing.documents.isEmpty else { return }

            let now = Date()
            let batch = db.batch()
            for seed in MockData.seedMessages(for: communityId) {
                let doc = messagesRef.document()
                let sentAt = now.addingTimeInterval(-Double(seed.minutesAgo) * 60)
                batch.setData([
                    "senderId": "seed_\(seed.senderUsername)",
                    "senderUsername": seed.senderUsername,
                    "senderCharacter": seed.senderCharacter.rawValue,
                    "text": seed.text,
                    "sentAt": Timestamp(date: sentAt)
                ], forDocument: doc)
            }
            try await batch.commit()
        } catch {
            print("⚠️ FirestoreService: seedMockMessagesIfEmpty failed — \(error.localizedDescription)")
        }
    }
}
