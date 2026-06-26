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

    func nearbyLandmarkPins(around center: CLLocationCoordinate2D,
                            radius: CLLocationDistance = 1500,
                            limit: Int = 5) async -> [RouteRequest.Pin] {
        let request = MKLocalPointsOfInterestRequest(center: center, radius: radius)
        request.pointOfInterestFilter = categories

        do {
            let response = try await MKLocalSearch(request: request).start()
            let pins = response.mapItems.prefix(limit).enumerated().map { index, item in
                RouteRequest.Pin(id: "landmark-\(index)",
                                 title: item.name ?? "Landmark",
                                 lat: item.placemark.coordinate.latitude,
                                 lng: item.placemark.coordinate.longitude,
                                 exp: landmarkEXP)
            }
            print("📍 LandmarkSearchService: found \(pins.count) nearby (\(pins.map(\.title).joined(separator: ", ")))")
            return pins
        } catch {
            // Apple Maps POI coverage varies by region — degrade to mission-only
            // routes rather than failing the whole route generation.
            print("⚠️ LandmarkSearchService: nearby search failed — \(error.localizedDescription)")
            return []
        }
    }
}
