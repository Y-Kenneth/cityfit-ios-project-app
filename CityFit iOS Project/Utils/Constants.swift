import SwiftUI

enum Constants {
    /// Ngrok tunnel to the Flask backend.
    /// Update this every time Ngrok restarts (free tier changes the URL).
    static let backendURL = "https://lustrous-donor-cavalier.ngrok-free.dev"

    static let requestTimeout: TimeInterval = 20
    /// Route Crew runs 2 agents sequentially (Planner -> Calculator), roughly
    /// 2x the DeepSeek round-trips of Chat/Vision — needs more headroom.
    static let routeRequestTimeout: TimeInterval = 45
    static let missionCooldownHours: Double = 8

    enum EXP {
        static let perLevel = 500
        static let runningMultiplier = 2.0
        static let walkingMultiplier = 1.0
        static let stationaryMultiplier = 0.0
    }

    enum StorageKey {
        static let userProfile = "cityfit.userProfile"
        static let missions = "cityfit.missions"
        static let lastCompletionDate = "cityfit.lastCompletionDate"
    }
}

extension Color {
    static let cityBackground = Color(hex: "#0D0D1A")   // Deep dark navy
    static let cityCard       = Color(hex: "#1A1A2E")   // Card surface
    static let cityAccent     = Color(hex: "#00D4FF")   // Cyan — primary accent
    static let cityGreen      = Color(hex: "#39FF14")   // Neon green — EXP bar
    static let cityYellow     = Color(hex: "#FFD700")   // Gold — rewards
    static let cityPurple     = Color(hex: "#7B2FBE")   // Purple — secondary
    static let citySubtext    = Color(hex: "#8888AA")   // Dimmed text

    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red   = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue  = Double(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
