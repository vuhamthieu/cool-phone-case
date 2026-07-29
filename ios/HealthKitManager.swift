// HealthKitManager.swift
import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()

    @Published var stepCount: Int = 0
    @Published var heartRate: Int = 0
    @Published var activeCalories: Int = 0
    @Published var authorizationStatus: String = "Not Requested"
    @Published var isAuthorized: Bool = false

    // Typed identifiers we want to read
    private let typesToRead: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(hr) }
        if let cal = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(cal) }
        return types
    }()

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                self.authorizationStatus = "HealthKit not available"
            }
            completion(false)
            return
        }

        store.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                self.authorizationStatus = success ? "Authorized" : "Denied"
                if success {
                    self.fetchAllMetrics()
                }
                completion(success)
            }
        }
    }

    func fetchAllMetrics() {
        fetchTodayStepCount()
        fetchLatestHeartRate()
        fetchTodayActiveCalories()
    }

    // MARK: - Step Count
    private func fetchTodayStepCount() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
            let count = stats?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            DispatchQueue.main.async {
                self.stepCount = Int(count)
            }
        }
        store.execute(query)
    }

    // MARK: - Heart Rate (most recent sample)
    private func fetchLatestHeartRate() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            if let sample = samples?.first as? HKQuantitySample {
                let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                DispatchQueue.main.async {
                    self.heartRate = Int(bpm)
                }
            }
        }
        store.execute(query)
    }

    // MARK: - Active Calories
    private func fetchTodayActiveCalories() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
            let cal = stats?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            DispatchQueue.main.async {
                self.activeCalories = Int(cal)
            }
        }
        store.execute(query)
    }
}
