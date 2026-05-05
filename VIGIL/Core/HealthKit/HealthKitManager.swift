//
//  HealthKitManager.swift
//  VIGIL
//

import Foundation
import HealthKit
import Observation

extension Notification.Name {
    static let vigilHealthKitDataChanged = Notification.Name("vigil.healthKit.dataChanged")
}

/// Singleton for **read-only** HealthKit access. Uses mock payloads whenever `HealthKit` is unavailable (e.g. Simulator).
@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    /// True when Health data is unavailable for this runtime (typically Simulator).
    var usesMockData: Bool {
        !HKHealthStore.isHealthDataAvailable()
    }

    private var didStartBackgroundObservers = false

    private init() {}

    // MARK: - Types (read only; never write)

    private static let readObjectTypes: Set<HKObjectType> = {
        var set: Set<HKObjectType> = [HKObjectType.workoutType()]
        let quantityIds: [HKQuantityTypeIdentifier] = [
            .activeEnergyBurned,
            .heartRate,
            .stepCount,
        ]
        for id in quantityIds {
            if let t = HKQuantityType.quantityType(forIdentifier: id) {
                set.insert(t)
            }
        }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            set.insert(sleep)
        }
        if let mindful = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
            set.insert(mindful)
        }
        return set
    }()

    // MARK: - Authorization

    /// READ ONLY — workouts, active energy, heart rate, step count, sleep analysis, mindful minutes.
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.requestAuthorization(toShare: [], read: Self.readObjectTypes) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        }
    }

    // MARK: - Fetch

    func fetchTodayWorkouts() async -> [WorkoutSummary] {
        guard HKHealthStore.isHealthDataAvailable() else {
            return Self.mockWorkouts
        }

        let workoutSampleType = HKObjectType.workoutType()
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let sorts = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutSampleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sorts
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                let mapped = workouts.map { Self.mapWorkout($0, heartRateType: heartRateType) }
                continuation.resume(returning: mapped)
            }
            store.execute(query)
        }
    }

    func fetchTodaySteps() async -> Int {
        guard HKHealthStore.isHealthDataAvailable() else {
            return Self.mockSteps
        }
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return Self.mockSteps
        }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if error != nil {
                    continuation.resume(returning: 0)
                    return
                }
                guard let quantity = statistics?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let raw = quantity.doubleValue(for: HKUnit.count())
                continuation.resume(returning: Int(raw.rounded()))
            }
            store.execute(query)
        }
    }

    func fetchLastNightSleep() async -> SleepSummary? {
        guard HKHealthStore.isHealthDataAvailable() else {
            return Self.mockSleep
        }
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return Self.mockSleep
        }

        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        let windowStart = cal.date(byAdding: .hour, value: -22, to: startOfToday) ?? startOfToday.addingTimeInterval(-22 * 3600)
        let windowEnd = cal.date(byAdding: .hour, value: 18, to: startOfToday) ?? Date()

        let predicate = HKQuery.predicateForSamples(withStart: windowStart, end: windowEnd, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: nil)
                    return
                }
                guard let categories = samples as? [HKCategorySample], !categories.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                let asleep = categories.filter(Self.isSampleAsleepSleep)
                guard !asleep.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                let seconds = asleep.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                let hours = seconds / 3600

                let startBound = asleep.map(\.startDate).min() ?? windowStart
                let endBound = asleep.map(\.endDate).max() ?? windowEnd
                let quality = Self.sleepQuality(heuristicHours: hours)

                continuation.resume(
                    returning: SleepSummary(
                        totalHours: hours,
                        quality: quality,
                        startTime: startBound,
                        endTime: endBound
                    )
                )
            }
            store.execute(query)
        }
    }

    func fetchTodayHeartRate() async -> Int? {
        guard HKHealthStore.isHealthDataAvailable() else {
            return Self.mockHeartRate
        }
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return Self.mockHeartRate
        }

        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: hrType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                if error != nil {
                    continuation.resume(returning: nil)
                    return
                }
                guard let qty = statistics?.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                let bpmUnit = HKUnit.count().unitDivided(by: .minute())
                let average = qty.doubleValue(for: bpmUnit)
                continuation.resume(returning: Int(average.rounded()))
            }
            store.execute(query)
        }
    }

    func fetchTodayMindfulMinutes() async -> Double {
        guard HKHealthStore.isHealthDataAvailable() else {
            return Self.mockMindfulMinutes
        }

        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else {
            return Self.mockMindfulMinutes
        }

        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: 0)
                    return
                }
                guard let mindful = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                let minutes = mindful.reduce(into: 0.0) { sum, sample in
                    sum += sample.endDate.timeIntervalSince(sample.startDate) / 60
                }
                continuation.resume(returning: minutes)
            }
            store.execute(query)
        }
    }

    // MARK: - Background observers + delivery

    func startBackgroundObserversIfNeeded() async {
        guard HKHealthStore.isHealthDataAvailable(), !didStartBackgroundObservers else { return }
        didStartBackgroundObservers = true

        for objectType in Self.readObjectTypes {
            guard let sampleType = objectType as? HKSampleType else { continue }
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { _, completionHandler, _ in
                Task { @MainActor in
                    NotificationCenter.default.post(name: .vigilHealthKitDataChanged, object: nil)
                }
                completionHandler()
            }
            store.execute(query)

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                store.enableBackgroundDelivery(for: objectType, frequency: .immediate) { _, _ in
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Mapping helpers

    private static func mapWorkout(_ workout: HKWorkout, heartRateType: HKQuantityType?) -> WorkoutSummary {
        let minutes = max(0, Int((workout.duration / 60).rounded(.towardZero)))
        let kcal = workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0

        var avgHR: Int?
        if let heartRateType, let stats = workout.statistics(for: heartRateType),
           let q = stats.averageQuantity() {
            let bpm = HKUnit.count().unitDivided(by: .minute())
            avgHR = Int(q.doubleValue(for: bpm).rounded())
        }

        return WorkoutSummary(
            durationMinutes: minutes,
            calories: kcal,
            avgHeartRate: avgHR,
            startTime: workout.startDate,
            endTime: workout.endDate
        )
    }

    private static func isSampleAsleepSleep(_ sample: HKCategorySample) -> Bool {
        guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
            return false
        }
        switch value {
        case .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM:
            return true
        default:
            return false
        }
    }

    private static func sleepQuality(heuristicHours: Double) -> SleepQuality {
        if heuristicHours >= 8 { return .excellent }
        if heuristicHours >= 7 { return .good }
        if heuristicHours >= 5.5 { return .fair }
        return .poor
    }

    // MARK: - Mock payloads (no HealthKit on Simulator)

    private static let mockWorkouts: [WorkoutSummary] = [
        WorkoutSummary(
            durationMinutes: 42,
            calories: 310,
            avgHeartRate: 148,
            startTime: Date().addingTimeInterval(-3600 * 3),
            endTime: Date().addingTimeInterval(-3600 * 2.3)
        ),
    ]
    private static let mockSteps = 8_432
    private static let mockSleep = SleepSummary(
        totalHours: 7.25,
        quality: .good,
        startTime: Date().addingTimeInterval(-3600 * 10),
        endTime: Date().addingTimeInterval(-3600 * 2.5)
    )
    private static let mockHeartRate: Int? = 74
    private static let mockMindfulMinutes: Double = 18
}
