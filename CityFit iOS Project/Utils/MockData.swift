import Foundation
import CoreLocation

enum MockData {

    // MARK: - Missions
    static let missions: [Mission] = [
        // Step missions
        Mission(id: "m1", title: "Daily Walker",
                description: "Walk 1000 steps today",
                type: .steps, targetValue: 1000, currentValue: 0,
                expReward: 100, difficulty: .easy, status: .available,
                timeLimit: nil, targetObject: nil, coordinate: nil),

        Mission(id: "m2", title: "Weekend Warrior",
                description: "Complete 3000 steps today",
                type: .steps, targetValue: 3000, currentValue: 0,
                expReward: 300, difficulty: .hard, status: .available,
                timeLimit: nil, targetObject: nil, coordinate: nil),

        // Distance missions
        Mission(id: "m3", title: "Morning Sprinter",
                description: "Run 500m before 9AM",
                type: .distance, targetValue: 500, currentValue: 0,
                expReward: 150, difficulty: .medium, status: .available,
                timeLimit: 60, targetObject: nil,
                coordinate: CLLocationCoordinate2D(latitude: 32.0620, longitude: 118.7980)),

        Mission(id: "m4", title: "City Explorer",
                description: "Walk 1km around your city",
                type: .distance, targetValue: 1000, currentValue: 0,
                expReward: 200, difficulty: .medium, status: .available,
                timeLimit: nil, targetObject: nil,
                coordinate: CLLocationCoordinate2D(latitude: 32.0590, longitude: 118.7950)),

        // Photo missions
        Mission(id: "m5", title: "Bottle Hunter",
                description: "Find 2 bottles anywhere around you",
                type: .photo, targetValue: 2, currentValue: 0,
                expReward: 180, difficulty: .easy, status: .available,
                timeLimit: nil, targetObject: "bottle", coordinate: nil),

        Mission(id: "m6", title: "Cyclist Tracker",
                description: "Spot a bicycle anywhere in the city",
                type: .photo, targetValue: 1, currentValue: 0,
                expReward: 250, difficulty: .easy, status: .available,
                timeLimit: nil, targetObject: "bicycle", coordinate: nil),

        Mission(id: "m7", title: "Nature Spotter",
                description: "Photograph a plant, flower, or tree nearby",
                type: .photo, targetValue: 1, currentValue: 0,
                expReward: 150, difficulty: .easy, status: .available,
                timeLimit: nil, targetObject: "plant", coordinate: nil),

        Mission(id: "m8", title: "Seat Finder",
                description: "Find and snap a bench or seat nearby",
                type: .photo, targetValue: 1, currentValue: 0,
                expReward: 120, difficulty: .easy, status: .available,
                timeLimit: nil, targetObject: "chair", coordinate: nil),

        Mission(id: "m9", title: "People Watcher",
                description: "Photograph a person you spot on your walk",
                type: .photo, targetValue: 1, currentValue: 0,
                expReward: 200, difficulty: .medium, status: .available,
                timeLimit: nil, targetObject: "person", coordinate: nil),

        Mission(id: "m10", title: "Clean City",
                description: "Find 2 trash bins on your route",
                type: .photo, targetValue: 2, currentValue: 0,
                expReward: 180, difficulty: .easy, status: .available,
                timeLimit: nil, targetObject: "trashbin", coordinate: nil),

        Mission(id: "m11", title: "Parking Lot Patrol",
                description: "Spot and photograph a car",
                type: .photo, targetValue: 1, currentValue: 0,
                expReward: 150, difficulty: .easy, status: .available,
                timeLimit: nil, targetObject: "car", coordinate: nil),

        Mission(id: "m12", title: "Tech Spotter",
                description: "Find someone's laptop or computer and take a picture of it",
                type: .photo, targetValue: 1, currentValue: 0,
                expReward: 200, difficulty: .medium, status: .available,
                timeLimit: nil, targetObject: "computer", coordinate: nil),

        Mission(id: "m13", title: "Cat Spotter",
                description: "Find a cat hiding somewhere in the city",
                type: .photo, targetValue: 1, currentValue: 0,
                expReward: 300, difficulty: .hard, status: .available,
                timeLimit: nil, targetObject: "cat", coordinate: nil),
    ]

    // MARK: - Leaderboard (current user at rank 5)
    static let leaderboard: [LeaderboardEntry] = [
        LeaderboardEntry(rank: 1, username: "SpeedKing99",  exp: 8420, level: 16, character: .sportsmanM),
        LeaderboardEntry(rank: 2, username: "RunnerGirl",   exp: 7890, level: 15, character: .sportsmanF),
        LeaderboardEntry(rank: 3, username: "CityWalker",   exp: 6540, level: 13, character: .studentF),
        LeaderboardEntry(rank: 4, username: "BunnyHops",    exp: 5320, level: 10, character: .rabbit),
        LeaderboardEntry(rank: 5, username: "YouAreHere",   exp: 1340, level: 5,  character: .sportsmanM),
        LeaderboardEntry(rank: 6, username: "StepMaster",   exp: 1100, level: 4,  character: .studentF),
        LeaderboardEntry(rank: 7, username: "NightRunner",  exp: 890,  level: 3,  character: .sportsmanF),
        LeaderboardEntry(rank: 8, username: "LazyToActive", exp: 620,  level: 2,  character: .rabbit),
    ]

    static let currentUserRank = 5

    // MARK: - Communities
    static let communities: [Community] = [
        Community(id: "c1", name: "Morning Runners",
                  description: "Early birds who run before sunrise",
                  memberCount: 1243, isJoined: false, tags: ["running", "morning"]),
        Community(id: "c2", name: "Weekend Warriors",
                  description: "Make every weekend count",
                  memberCount: 892, isJoined: true, tags: ["weekend", "casual"]),
        Community(id: "c3", name: "City Explorers",
                  description: "Discover hidden gems on foot",
                  memberCount: 567, isJoined: false, tags: ["walking", "exploration"]),
        Community(id: "c4", name: "Step Counter Squad",
                  description: "Daily step challenges and accountability",
                  memberCount: 2104, isJoined: false, tags: ["steps", "challenge"]),
        Community(id: "c5", name: "Campus Walkers",
                  description: "Students walking beyond class",
                  memberCount: 431, isJoined: false, tags: ["student", "campus"]),
    ]

    // MARK: - Mock Map Events (Nanjing coordinates)
    static let gameEvents: [GameEvent] = [
        GameEvent(id: "e1", title: "5K Fun Run",
                  description: "Community run around Xuanwu Lake",
                  coordinate: CLLocationCoordinate2D(latitude: 32.0742, longitude: 118.7975),
                  expReward: 500, eventType: .run),
        GameEvent(id: "e2", title: "Morning Yoga",
                  description: "Group yoga at Purple Mountain",
                  coordinate: CLLocationCoordinate2D(latitude: 32.0603, longitude: 118.8464),
                  expReward: 200, eventType: .wellness),
        GameEvent(id: "e3", title: "City Walk Challenge",
                  description: "Walk the historic Qinhuai River route",
                  coordinate: CLLocationCoordinate2D(latitude: 32.0176, longitude: 118.7975),
                  expReward: 350, eventType: .walk),
    ]

    // MARK: - Community posts (CommunityDetailView)
    static let communityPosts: [(author: String, text: String, time: String)] = [
        ("SpeedKing99", "Crushed a 5K around Xuanwu Lake this morning! 🏃", "2h ago"),
        ("RunnerGirl", "Anyone up for a weekend walk along the Qinhuai River?", "5h ago"),
        ("CityWalker", "Hit my 10,000 step streak — day 14! 🔥", "1d ago"),
    ]
}
