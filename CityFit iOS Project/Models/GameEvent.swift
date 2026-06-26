import Foundation
import CoreLocation
import SwiftUI

struct GameEvent: Identifiable {
    let id: String
    let title: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let expReward: Int
    let eventType: EventType
}

enum EventType {
    case run, wellness, walk

    var icon: String {
        switch self {
        case .run:      return "figure.run"
        case .wellness: return "heart.fill"
        case .walk:     return "figure.walk"
        }
    }

    var color: Color {
        switch self {
        case .run:      return .cityYellow
        case .wellness: return .cityPurple
        case .walk:     return .cityGreen
        }
    }

    /// Header photo for the event detail sheet — bundled as a local Asset
    /// Catalog image (not fetched at runtime): Wikimedia Commons, the
    /// original source, is blocked in mainland China, which made the photo
    /// silently fail to load there even with a VPN that routes other traffic.
    var headerImageName: String {
        switch self {
        case .run:      return "eventRun"
        case .wellness: return "eventWellness"
        case .walk:     return "eventWalk"
        }
    }
}
