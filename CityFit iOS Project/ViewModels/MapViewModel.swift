import Foundation
import MapKit
import SwiftUI

/// A unified map annotation item: mission pins + mock game event pins.
struct MapPinItem: Identifiable {
    enum Kind { case mission, event }

    let id: String
    let title: String
    let coordinate: CLLocationCoordinate2D
    let kind: Kind
    let color: Color
    let icon: String
}

final class MapViewModel: ObservableObject {
    @Published var routeOverlays: [MKPolyline] = []
    @Published var routeWaypoints: [RouteResponse.Waypoint] = []

    // MARK: - Trip planning (user-picked point A/B on the Home map)

    @Published var isPlanningTrip = false
    @Published var tripOrigin: CLLocationCoordinate2D?
    @Published var tripDestination: CLLocationCoordinate2D?
    @Published var tripPolyline: MKPolyline?
    @Published var tripDistanceMeters: CLLocationDistance?

    func pins(missions: [Mission], events: [GameEvent]) -> [MapPinItem] {
        let missionPins = missions.compactMap { mission -> MapPinItem? in
            guard let coordinate = mission.coordinate else { return nil }
            return MapPinItem(id: "mission-\(mission.id)",
                              title: mission.title,
                              coordinate: coordinate,
                              kind: .mission,
                              color: .cityAccent,
                              icon: "bolt.fill")
        }
        let eventPins = events.map { event in
            MapPinItem(id: "event-\(event.id)",
                       title: event.title,
                       coordinate: event.coordinate,
                       kind: .event,
                       color: event.eventType.color,
                       icon: event.eventType.icon)
        }
        return missionPins + eventPins
    }

    // MARK: - AI route drawing

    /// Connects AI waypoints with MKDirections walking segments.
    func drawRoute(waypoints: [RouteResponse.Waypoint]) {
        routeOverlays = []
        routeWaypoints = waypoints
        let coordinates = waypoints.map(\.coordinate)
        guard coordinates.count >= 2 else { return }

        for index in 0..<(coordinates.count - 1) {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinates[index]))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinates[index + 1]))
            request.transportType = .walking
            MKDirections(request: request).calculate { [weak self] response, _ in
                guard let polyline = response?.routes.first?.polyline else { return }
                DispatchQueue.main.async {
                    self?.routeOverlays.append(polyline)
                }
            }
        }
    }

    func clearRoute() {
        routeOverlays = []
        routeWaypoints = []
    }

    // MARK: - Trip planning

    func beginPlanningTrip() {
        isPlanningTrip = true
        tripOrigin = nil
        tripDestination = nil
        tripPolyline = nil
        tripDistanceMeters = nil
    }

    func cancelPlanningTrip() {
        isPlanningTrip = false
        tripOrigin = nil
        tripDestination = nil
        tripPolyline = nil
        tripDistanceMeters = nil
    }

    /// First tap while planning sets the origin, second sets the destination
    /// and kicks off the real MapKit walking-distance lookup.
    func handleTripTap(_ coordinate: CLLocationCoordinate2D) {
        guard isPlanningTrip else { return }
        if tripOrigin == nil {
            tripOrigin = coordinate
        } else if tripDestination == nil {
            tripDestination = coordinate
            fetchTripDistance()
        }
    }

    /// The backend's Trip Crew agents can't call Apple's MapKit themselves —
    /// only the device can — so the real walking distance is measured here,
    /// on-device, and handed to the AI as ground truth (same MKDirections
    /// pattern as drawRoute() above).
    private func fetchTripDistance() {
        guard let origin = tripOrigin, let destination = tripDestination else { return }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking
        MKDirections(request: request).calculate { [weak self] response, _ in
            guard let route = response?.routes.first else { return }
            DispatchQueue.main.async {
                self?.tripPolyline = route.polyline
                self?.tripDistanceMeters = route.distance
            }
        }
    }
}
