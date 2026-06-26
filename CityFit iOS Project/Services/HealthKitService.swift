import Foundation
import HealthKit

/// Reads body mass, height, resting heart rate, active energy, and biological
/// sex from Apple Health. HealthKit has no Simulator data source at all (no
/// device to generate real samples), so `isHealthDataAvailable` is reliably
/// false there — callers should fall back to the user's manually-entered
/// signup values, same fallback shape as PedometerService's simulator mock.
final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        types.insert(HKObjectType.characteristicType(forIdentifier: .biologicalSex)!)
        return types
    }

    struct HealthSnapshot {
        var weightKg: Double?
        var heightCm: Double?
        var gender: Gender?
        var restingHeartRate: Int?
        var activeEnergyKcal: Double?
    }

    /// Requests read authorization, then immediately pulls the latest sample
    /// of each metric. Returns nil if HealthKit is unavailable (e.g. Simulator)
    /// or the user denies the permission sheet.
    func requestAuthorizationAndFetch() async -> HealthSnapshot? {
        guard isAvailable else { return nil }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
        } catch {
            print("⚠️ HealthKitService: authorization failed — \(error.localizedDescription)")
            return nil
        }
        return await fetchSnapshot()
    }

    private func fetchSnapshot() async -> HealthSnapshot {
        async let weight = latestQuantitySample(.bodyMass, unit: .gramUnit(with: .kilo))
        async let height = latestQuantitySample(.height, unit: .meterUnit(with: .centi))
        async let restingHR = latestQuantitySample(.restingHeartRate, unit: HKUnit(from: "count/min"))
        async let activeEnergy = latestQuantitySample(.activeEnergyBurned, unit: .kilocalorie())

        return HealthSnapshot(
            weightKg: await weight,
            heightCm: await height,
            gender: biologicalSex(),
            restingHeartRate: (await restingHR).map { Int($0.rounded()) },
            activeEnergyKcal: await activeEnergy
        )
    }

    private func biologicalSex() -> Gender? {
        guard let sex = try? store.biologicalSex().biologicalSex else { return nil }
        switch sex {
        case .male:   return .male
        case .female: return .female
        default:      return nil
        }
    }

    private func latestQuantitySample(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}
