import Foundation
import MapKit

/// Finds real nearby points of interest via Apple Maps' own POI database
/// (MKLocalPointsOfInterestRequest — on-device, free, no API key) so
/// AI-generated routes can include real landmarks alongside CityFit's own
/// missions, not just the app's mock pins.
final class LandmarkSearchService {
    static let shared = LandmarkSearchService()

    private init() {}

    /// An excluding filter (everything EXCEPT these) instead of an including
    /// one — a narrow whitelist (parks/museums/stadiums/etc.) returned zero
    /// results in ordinary residential/campus areas, since real nearby POIs
    /// there are mundane things like cafes and food stalls. Only filter out
    /// categories that make no sense as a walking-route stop.
    private let categories = MKPointOfInterestFilter(excluding: [
        .atm, .bank, .carRental, .evCharger, .fireStation, .gasStation,
        .hospital, .laundry, .parking, .pharmacy, .police, .postOffice,
        .restroom
    ])

    /// Real-world places don't come with a CityFit EXP value — a flat reward
    /// distinctly lower than a typical mission (~100-300) keeps missions the
    /// primary EXP source while still making landmarks worth detouring for.
    private let landmarkEXP = 80

    /// Natural-language categories searched in addition to the structured POI
    /// database. Apple's `MKLocalPointsOfInterestRequest` returns little or
    /// nothing in some regions (notably mainland China, where MapKit is served
    /// by a local provider), which left routes with only the app's 3 mock
    /// mission pins — so they came out identical every time, with no real
    /// places. Natural-language search has much broader coverage there.
    private let categoryQueries = ["park", "cafe", "restaurant", "store",
                                   "supermarket", "shopping mall"]

    func nearbyLandmarkPins(around center: CLLocationCoordinate2D,
                            radius: CLLocationDistance = 1500,
                            limit: Int = 6) async -> [RouteRequest.Pin] {
        var items: [MKMapItem] = []

        // 1. Apple's structured POI database.
        let poiRequest = MKLocalPointsOfInterestRequest(center: center, radius: radius)
        poiRequest.pointOfInterestFilter = categories
        if let response = try? await MKLocalSearch(request: poiRequest).start() {
            items += response.mapItems
        }

        // 2. Natural-language category searches, run concurrently.
        let region = MKCoordinateRegion(center: center,
                                        latitudinalMeters: radius * 2,
                                        longitudinalMeters: radius * 2)
        await withTaskGroup(of: [MKMapItem].self) { group in
            for query in categoryQueries {
                group.addTask {
                    let request = MKLocalSearch.Request()
                    request.naturalLanguageQuery = query
                    request.region = region
                    return (try? await MKLocalSearch(request: request).start())?.mapItems ?? []
                }
            }
            for await result in group { items += result }
        }

        // Dedupe by name, keep only those actually within the radius, then
        // shuffle so each generation offers a different subset — that variety
        // is what stops the AI returning the same route every time.
        var seen = Set<String>()
        let nearby = items.filter { item in
            guard let name = item.name, !name.isEmpty, seen.insert(name).inserted else { return false }
            let distance = CLLocation(latitude: item.placemark.coordinate.latitude,
                                      longitude: item.placemark.coordinate.longitude)
                .distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude))
            return distance <= radius
        }
        let pins = nearby.shuffled().prefix(limit).enumerated().map { index, item in
            RouteRequest.Pin(id: "landmark-\(index)",
                             title: item.name ?? "Landmark",
                             lat: item.placemark.coordinate.latitude,
                             lng: item.placemark.coordinate.longitude,
                             exp: landmarkEXP)
        }
        print("📍 LandmarkSearchService: found \(pins.count) nearby (\(pins.map(\.title).joined(separator: ", ")))")
        return Array(pins)
    }
}
