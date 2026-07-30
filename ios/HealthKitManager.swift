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

    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        print("━━━━ HealthKit: requestAuthorization() called ━━━━")
        guard HKHealthStore.isHealthDataAvailable() else {
            print("✗ HealthKit: isHealthDataAvailable() == FALSE — running on simulator or unsupported device")
            DispatchQueue.main.async {
                self.authorizationStatus = "Not available on this device"
                self.isAuthorized = false
            }
            completion(false)
            return
        }
        print("✓ HealthKit: isHealthDataAvailable() == TRUE")

        for type in typesToRead {
            let status = store.authorizationStatus(for: type)
            print("  Pre-auth status for \(type.identifier): \(status.rawValue) " +
                  "(0=notDetermined, 1=sharingDenied, 2=sharingAuthorized)")
        }

        print("HealthKit: Calling store.requestAuthorization — sheet should appear now...")
        store.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            print("━━━━ HealthKit: requestAuthorization callback ━━━━")
            print("  success = \(success)")

            if let err = error {
                print("✗ HealthKit error: \(err.localizedDescription)")
                print("  Error domain: \((err as NSError).domain)")
                print("  Error code  : \((err as NSError).code)")
            } else {
                print("✓ HealthKit: No error in callback")
            }

            for type in self.typesToRead {
                let status = self.store.authorizationStatus(for: type)
                print("  Post-auth status for \(type.identifier): \(status.rawValue)")
            }

            DispatchQueue.main.async {
                self.isAuthorized = success
                self.authorizationStatus = success ? "Authorized ✓" : "Denied / Not Determined"
                print("HealthKit: Published isAuthorized = \(success)")
                if success {
                    print("HealthKit: Triggering initial metric fetch...")
                    self.fetchAllMetrics()
                } else {
                    print("HealthKit: Authorization NOT granted — skipping fetch")
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
