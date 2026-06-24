import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - User Profile

    func saveUserProfile(_ profile: UserProfile) async throws {
        let data: [String: Any] = [
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
            "joinedCommunityIds": profile.joinedCommunityIds
        ]
        try await db.collection("users").document(profile.id).setData(data, merge: true)
    }

    func fetchUserProfile(uid: String) async throws -> UserProfile? {
        let doc = try await db.collection("users").document(uid).getDocument()
        guard let d = doc.data() else { return nil }

        let character = CharacterType(rawValue: d["character"] as? String ?? "") ?? .sportsmanM
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
            joinedCommunityIds: d["joinedCommunityIds"] as? [String] ?? []
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
}
