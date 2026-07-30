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
        print("HealthKit: Checking availability...")
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit: Not available on this device.")
            DispatchQueue.main.async {
                self.authorizationStatus = "HealthKit not available"
                self.isAuthorized = false
            }
            completion(false)
            return
        }

        print("HealthKit: Requesting authorization for read types: \(typesToRead)")
        store.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit: Authorization request encountered error: \(error.localizedDescription)")
            } else {
                print("HealthKit: Authorization request completed with success: \(success)")
            }
            
            DispatchQueue.main.async {
                self.isAuthorized = success
                self.authorizationStatus = success ? "Authorized" : "Denied"
                if success {
                    print("HealthKit: Fetching initial metrics post-auth...")
                    self.fetchAllMetrics()
                }
                completion(success)
            }
        }
    }

    func fetchAllMetrics() {
        print("HealthKit: Fetching all active metrics...")
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

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
            if let error = error {
                print("HealthKit: Step Count query error: \(error.localizedDescription)")
                return
            }
            let count = stats?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            print("HealthKit: Steps fetched successfully: \(Int(count))")
            DispatchQueue.main.async {
                self.stepCount = Int(count)
                self.isAuthorized = true // If query succeeds, we have access
            }
        }
        store.execute(query)
    }

    // MARK: - Heart Rate (most recent sample)
    private func fetchLatestHeartRate() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("HealthKit: Heart Rate query error: \(error.localizedDescription)")
                return
            }
            if let sample = samples?.first as? HKQuantitySample {
                let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                print("HealthKit: Heart Rate fetched successfully: \(Int(bpm)) BPM")
                DispatchQueue.main.async {
                    self.heartRate = Int(bpm)
                    self.isAuthorized = true
                }
            } else {
                print("HealthKit: No Heart Rate samples found.")
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

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
            if let error = error {
                print("HealthKit: Calories query error: \(error.localizedDescription)")
                return
            }
            let cal = stats?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            print("HealthKit: Calories fetched successfully: \(Int(cal)) KCAL")
            DispatchQueue.main.async {
                self.activeCalories = Int(cal)
                self.isAuthorized = true
            }
        }
        store.execute(query)
    }
}
