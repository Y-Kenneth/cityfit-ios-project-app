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
                description: "Find a bottle anywhere around you",
                type: .photo, targetValue: 1, currentValue: 0,
                expReward: 120, difficulty: .easy, status: .available,
                timeLimit: nil, targetObject: "bottle", coordinate: nil),

        Mission(id: "m6", title: "Cyclist Tracker",
                description: "Spot a bicycle anywhere in the city",
                type: .photo, targetValue: 1, currentValue: 0,
                expReward: 200, difficulty: .easy, status: .available,
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

        Mission(id: "m9", title: "Selfie Challenge",
                description: "Take a selfie — switch to front camera and smile!",
                type: .photo, targetValue: 1, currentValue: 0,
                expReward: 150, difficulty: .easy, status: .available,
                timeLimit: nil, targetObject: "person", coordinate: nil),

        Mission(id: "m10", title: "Eco Warrior",
                description: "Find a trash bin — every bit of awareness counts",
                type: .photo, targetValue: 1, currentValue: 0,
                expReward: 150, difficulty: .easy, status: .available,
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

        Mission(id: "m14", title: "Urban Safari",
                description: "Photograph a plant AND a cat on your walk",
                type: .photo, targetValue: 2, currentValue: 0,
                expReward: 400, difficulty: .hard, status: .available,
                timeLimit: 30, targetObject: "plant", coordinate: nil),

        Mission(id: "m15", title: "Street Snapshot",
                description: "Capture a bicycle out in the wild",
                type: .photo, targetValue: 1, currentValue: 0,
                expReward: 180, difficulty: .medium, status: .available,
                timeLimit: 20, targetObject: "bicycle",
                coordinate: CLLocationCoordinate2D(latitude: 32.0610, longitude: 118.7970)),

        Mission(id: "m16", title: "Green Thumb",
                description: "Find 2 different plants on your route",
                type: .photo, targetValue: 2, currentValue: 0,
                expReward: 250, difficulty: .medium, status: .available,
                timeLimit: nil, targetObject: "plant", coordinate: nil),

        Mission(id: "m17", title: "Face the Day",
                description: "Start your mission with a selfie — front camera, big smile!",
                type: .photo, targetValue: 1, currentValue: 0,
                expReward: 100, difficulty: .easy, status: .available,
                timeLimit: nil, targetObject: "person", coordinate: nil),

        Mission(id: "m18", title: "Rush Hour",
                description: "Spot 2 cars during your city walk",
                type: .photo, targetValue: 2, currentValue: 0,
                expReward: 200, difficulty: .easy, status: .available,
                timeLimit: nil, targetObject: "car", coordinate: nil),
    ]

    // MARK: - Leaderboard (current user at rank 5)
    static let leaderboard: [LeaderboardEntry] = [
        LeaderboardEntry(rank: 1, username: "SpeedKing99",  exp: 8420, level: 16, character: .sportsmanM,
                          gender: .male, weightKg: 74, heightCm: 180, restingHeartRate: 52, activeEnergyKcal: 620, streak: 41, totalSteps: 184_200),
        LeaderboardEntry(rank: 2, username: "RunnerGirl",   exp: 7890, level: 15, character: .sportsmanF,
                          gender: .female, weightKg: 56, heightCm: 165, restingHeartRate: 55, activeEnergyKcal: 540, streak: 33, totalSteps: 171_500),
        LeaderboardEntry(rank: 3, username: "CityWalker",   exp: 6540, level: 13, character: .studentF,
                          gender: .female, weightKg: 60, heightCm: 168, restingHeartRate: 61, activeEnergyKcal: 410, streak: 27, totalSteps: 152_800),
        LeaderboardEntry(rank: 4, username: "BunnyHops",    exp: 5320, level: 10, character: .rabbit,
                          gender: .male, weightKg: 58, heightCm: 162, restingHeartRate: 64, activeEnergyKcal: 380, streak: 19, totalSteps: 119_400),
        LeaderboardEntry(rank: 5, username: "YouAreHere",   exp: 1340, level: 5,  character: .sportsmanM,
                          gender: .male, weightKg: 70, heightCm: 170, restingHeartRate: 66, activeEnergyKcal: 290, streak: 6,  totalSteps: 41_200),
        LeaderboardEntry(rank: 6, username: "StepMaster",   exp: 1100, level: 4,  character: .studentF,
                          gender: .female, weightKg: 52, heightCm: 158, restingHeartRate: 68, activeEnergyKcal: 260, streak: 5,  totalSteps: 35_700),
        LeaderboardEntry(rank: 7, username: "NightRunner",  exp: 890,  level: 3,  character: .sportsmanF,
                          gender: .female, weightKg: 63, heightCm: 170, restingHeartRate: 58, activeEnergyKcal: 300, streak: 4,  totalSteps: 28_900),
        LeaderboardEntry(rank: 8, username: "LazyToActive", exp: 620,  level: 2,  character: .rabbit,
                          gender: .male, weightKg: 82, heightCm: 175, restingHeartRate: 74, activeEnergyKcal: 180, streak: 2,  totalSteps: 19_300),
    ]

    static let currentUserRank = 5

    // MARK: - Communities
    // The catalog itself is just mock content — only "which ones did I join" is
    // real (saved on the user's own profile, see ProfileViewModel.toggleCommunity).
    static let communities: [Community] = [
        Community(id: "c1", name: "Morning Runners",
                  description: "Early birds who run before sunrise",
                  longDescription: """
                  Morning Runners is for early risers who believe the best miles happen before \
                  the city wakes up. Every session starts in the quiet hour just before sunrise — \
                  empty streets, cool air, and a pace that's whatever you bring that day.

                  Whether you're chasing a 5K personal best or just want company for an easy jog, \
                  this group keeps things low-pressure: no minimum pace, no mandatory distance. \
                  Show up, run, and watch the city wake up around you.
                  """,
                  imageURL: URL(string: "https://picsum.photos/seed/c1/800/450"),
                  tags: ["running", "morning"], memberCount: 1243, isJoined: false),
        Community(id: "c2", name: "Weekend Warriors",
                  description: "Make every weekend count",
                  longDescription: """
                  Weekday schedules are chaos, so Weekend Warriors saves all the momentum for \
                  Saturday and Sunday. Expect longer routes, group photo stops, and a much more \
                  social pace than your average training run.

                  This is the community for people who'd rather do one great two-hour outing a \
                  week than squeeze in five rushed ones. Bring snacks, bring friends, bring a \
                  camera — the weekend is the whole point.
                  """,
                  imageURL: URL(string: "https://picsum.photos/seed/c2/800/450"),
                  tags: ["weekend", "casual"], memberCount: 892, isJoined: false),
        Community(id: "c3", name: "City Explorers",
                  description: "Discover hidden gems on foot",
                  longDescription: """
                  City Explorers turns walking into a treasure hunt. Members swap routes that \
                  pass murals, hole-in-the-wall cafes, pocket parks, and the kind of side streets \
                  that never show up on a tourist map.

                  There's no pace requirement and no distance goal — the only rule is to notice \
                  something new every time you go out. Great for anyone who finds a familiar \
                  neighborhood boring on a treadmill but endlessly interesting on foot.
                  """,
                  imageURL: URL(string: "https://picsum.photos/seed/c3/800/450"),
                  tags: ["walking", "exploration"], memberCount: 567, isJoined: false),
        Community(id: "c4", name: "Step Counter Squad",
                  description: "Daily step challenges and accountability",
                  longDescription: """
                  Step Counter Squad is built around one simple idea: showing your numbers to \
                  other people makes you actually hit them. Members compare daily step counts, \
                  set weekly targets, and call each other out (kindly) when the count slips.

                  No running shoes required — this is for people who get their movement in \
                  errands, dog walks, and pacing around during phone calls, and want a reason \
                  to make today's total a little higher than yesterday's.
                  """,
                  imageURL: URL(string: "https://picsum.photos/seed/c4/800/450"),
                  tags: ["steps", "challenge"], memberCount: 2104, isJoined: false),
        Community(id: "c5", name: "Campus Walkers",
                  description: "Students walking beyond class",
                  longDescription: """
                  Campus Walkers is for students who want to turn the walk between classes — or \
                  the study break that's overdue — into something more intentional. Members trade \
                  favorite routes around campus, organize casual group walks between lectures, \
                  and use movement as a study-break reset instead of another scroll session.

                  Open to anyone studying anywhere; the "campus" is wherever you're based.
                  """,
                  imageURL: URL(string: "https://picsum.photos/seed/c5/800/450"),
                  tags: ["student", "campus"], memberCount: 431, isJoined: false),
    ]

    // MARK: - Community Chat Seed Data
    // Used to seed a new community's Firestore "messages" subcollection the
    // first time a user joins it, so the group chat never opens empty during
    // testing. Timestamps are relative offsets (minutes-ago) from "now" —
    // FirestoreService converts them to absolute Dates right before writing,
    // so the conversation always reads as "recent" no matter when it's seeded.
    struct SeedMessage {
        let senderUsername: String
        let senderCharacter: CharacterType
        let text: String
        let minutesAgo: Int
    }

    static func seedMessages(for communityId: String) -> [SeedMessage] {
        switch communityId {
        case "c1":
            return [
                SeedMessage(senderUsername: "SpeedKing99", senderCharacter: .sportsmanM, text: "morning runners, who's up for 5:45am tomorrow?", minutesAgo: 320),
                SeedMessage(senderUsername: "RunnerGirl", senderCharacter: .sportsmanF, text: "I'm in, same spot by the fountain?", minutesAgo: 318),
                SeedMessage(senderUsername: "SpeedKing99", senderCharacter: .sportsmanM, text: "yep, fountain then the river loop", minutesAgo: 316),
                SeedMessage(senderUsername: "NightRunner", senderCharacter: .sportsmanF, text: "ugh 5:45 is rough but ok 😭", minutesAgo: 90),
                SeedMessage(senderUsername: "CityWalker", senderCharacter: .studentF, text: "did 6k this morning, legs are dead", minutesAgo: 70),
                SeedMessage(senderUsername: "RunnerGirl", senderCharacter: .sportsmanF, text: "nice!! that's a new PR for you right", minutesAgo: 68),
                SeedMessage(senderUsername: "CityWalker", senderCharacter: .studentF, text: "yeah by like 2 minutes lol", minutesAgo: 65),
                SeedMessage(senderUsername: "SpeedKing99", senderCharacter: .sportsmanM, text: "let's go 🔥", minutesAgo: 64),
            ]
        case "c2":
            return [
                SeedMessage(senderUsername: "BunnyHops", senderCharacter: .rabbit, text: "weekend plan: river trail, 10am, anyone in?", minutesAgo: 240),
                SeedMessage(senderUsername: "StepMaster", senderCharacter: .studentF, text: "in! bringing snacks this time", minutesAgo: 235),
                SeedMessage(senderUsername: "LazyToActive", senderCharacter: .rabbit, text: "what kind of snacks asking for myself", minutesAgo: 233),
                SeedMessage(senderUsername: "StepMaster", senderCharacter: .studentF, text: "orange slices and those little buns", minutesAgo: 231),
                SeedMessage(senderUsername: "LazyToActive", senderCharacter: .rabbit, text: "ok i'm definitely coming now", minutesAgo: 230),
                SeedMessage(senderUsername: "BunnyHops", senderCharacter: .rabbit, text: "lol classic. last week's photos were great btw", minutesAgo: 95),
                SeedMessage(senderUsername: "StepMaster", senderCharacter: .studentF, text: "the sunset one is my new wallpaper ngl", minutesAgo: 92),
            ]
        case "c3":
            return [
                SeedMessage(senderUsername: "CityWalker", senderCharacter: .studentF, text: "found a mural near the old train yard, anyone been?", minutesAgo: 410),
                SeedMessage(senderUsername: "NightRunner", senderCharacter: .sportsmanF, text: "no!! send the location", minutesAgo: 405),
                SeedMessage(senderUsername: "CityWalker", senderCharacter: .studentF, text: "dropping a pin in the group route file later today", minutesAgo: 400),
                SeedMessage(senderUsername: "YouAreHere", senderCharacter: .sportsmanM, text: "there's also a tiny café two blocks from there, good detour", minutesAgo: 150),
                SeedMessage(senderUsername: "NightRunner", senderCharacter: .sportsmanF, text: "say less, adding it to the walk", minutesAgo: 148),
            ]
        case "c4":
            return [
                SeedMessage(senderUsername: "StepMaster", senderCharacter: .studentF, text: "daily count: 11,204. who's beating that", minutesAgo: 500),
                SeedMessage(senderUsername: "LazyToActive", senderCharacter: .rabbit, text: "...not me today, 3,000 and proud of it honestly", minutesAgo: 495),
                SeedMessage(senderUsername: "CityWalker", senderCharacter: .studentF, text: "every step counts 👏", minutesAgo: 493),
                SeedMessage(senderUsername: "SpeedKing99", senderCharacter: .sportsmanM, text: "14,002. took the long way to literally everything today", minutesAgo: 200),
                SeedMessage(senderUsername: "StepMaster", senderCharacter: .studentF, text: "show off 😂", minutesAgo: 198),
                SeedMessage(senderUsername: "SpeedKing99", senderCharacter: .sportsmanM, text: "🐢🐢🐢", minutesAgo: 197),
            ]
        case "c5":
            return [
                SeedMessage(senderUsername: "RunnerGirl", senderCharacter: .sportsmanF, text: "anyone walking to the north campus lecture at 2?", minutesAgo: 130),
                SeedMessage(senderUsername: "YouAreHere", senderCharacter: .sportsmanM, text: "yeah leaving library in 5", minutesAgo: 128),
                SeedMessage(senderUsername: "RunnerGirl", senderCharacter: .sportsmanF, text: "perfect, meet by the fountain steps", minutesAgo: 127),
                SeedMessage(senderUsername: "NightRunner", senderCharacter: .sportsmanF, text: "study break walk later? brain is fried", minutesAgo: 40),
                SeedMessage(senderUsername: "YouAreHere", senderCharacter: .sportsmanM, text: "always down for that", minutesAgo: 38),
            ]
        default:
            return [
                SeedMessage(senderUsername: "CityWalker", senderCharacter: .studentF, text: "welcome to the group! 👋", minutesAgo: 60),
                SeedMessage(senderUsername: "YouAreHere", senderCharacter: .sportsmanM, text: "good to be here, let's get moving", minutesAgo: 55),
            ]
        }
    }

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
}
