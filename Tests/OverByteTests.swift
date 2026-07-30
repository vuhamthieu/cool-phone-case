import XCTest
@testable import OverByte

final class BLEManagerTests: XCTestCase {
    func testSyncTimePayloadIsLittleEndian() {
        let now = UInt32(Date().timeIntervalSince1970)
        var payload = Data(count: 4)
        payload.withUnsafeMutableBytes { ptr in
            ptr.storeBytes(of: now.littleEndian, toByteOffset: 0, as: UInt32.self)
        }

        XCTAssertEqual(payload.count, 4, "Payload must be exactly 4 bytes")

        var decoded: UInt32 = 0
        _ = withUnsafeMutableBytes(of: &decoded) { payload.copyBytes(to: $0) }
        let result = UInt32(littleEndian: decoded)

        XCTAssertEqual(result, now, "Decoded timestamp must match original")
    }
}
