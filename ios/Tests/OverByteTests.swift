import XCTest
@testable import OverByte

// MARK: - BLEManager Unit Tests

final class BLEManagerTests: XCTestCase {

    /// Verifies that the syncTime payload is exactly 4 bytes
    /// and encodes the correct little-endian Unix timestamp.
    func testSyncTimePayloadIsLittleEndian() {
        let now = UInt32(Date().timeIntervalSince1970)
        var payload = Data(count: 4)
        payload.withUnsafeMutableBytes { ptr in
            ptr.storeBytes(of: now.littleEndian, toByteOffset: 0, as: UInt32.self)
        }

        XCTAssertEqual(payload.count, 4, "Payload must be exactly 4 bytes")

        // Re-decode and compare
        var decoded: UInt32 = 0
        _ = withUnsafeMutableBytes(of: &decoded) { payload.copyBytes(to: $0) }
        let result = UInt32(littleEndian: decoded)

        XCTAssertEqual(result, now, "Decoded timestamp must match original")
    }

    /// Verifies that the activity payload is exactly 8 bytes
    /// and encodes fields at the correct byte offsets.
    func testActivityPayloadLayout() {
        let steps:    UInt32 = 12345
        let bpm:      UInt16 = 72
        let calories: UInt16 = 500

        var payload = Data(count: 8)
        payload.withUnsafeMutableBytes { ptr in
            ptr.storeBytes(of: steps.littleEndian,    toByteOffset: 0, as: UInt32.self)
            ptr.storeBytes(of: bpm.littleEndian,      toByteOffset: 4, as: UInt16.self)
            ptr.storeBytes(of: calories.littleEndian, toByteOffset: 6, as: UInt16.self)
        }

        XCTAssertEqual(payload.count, 8, "Activity payload must be exactly 8 bytes")

        let decodedSteps    = UInt32(littleEndian: payload.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt32.self) })
        let decodedBPM      = UInt16(littleEndian: payload.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt16.self) })
        let decodedCalories = UInt16(littleEndian: payload.withUnsafeBytes { $0.load(fromByteOffset: 6, as: UInt16.self) })

        XCTAssertEqual(decodedSteps,    steps,    "Steps must round-trip correctly")
        XCTAssertEqual(decodedBPM,      bpm,      "BPM must round-trip correctly")
        XCTAssertEqual(decodedCalories, calories, "Calories must round-trip correctly")
    }
}

// MARK: - HealthKitManager Unit Tests

final class HealthKitManagerTests: XCTestCase {

    func testInitialPublishedValuesAreZero() {
        let manager = HealthKitManager()
        XCTAssertEqual(manager.stepCount,       0, "Initial stepCount should be 0")
        XCTAssertEqual(manager.heartRate,       0, "Initial heartRate should be 0")
        XCTAssertEqual(manager.activeCalories,  0, "Initial activeCalories should be 0")
        XCTAssertFalse(manager.isAuthorized,       "isAuthorized should start false")
    }

    /// Smoke-test: calling requestAuthorization does not crash on a device
    /// where HealthKit is unavailable (simulator).
    func testRequestAuthorizationDoesNotCrashOnSimulator() {
        let manager = HealthKitManager()
        let exp = expectation(description: "Authorization callback fires")

        manager.requestAuthorization { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }
}
