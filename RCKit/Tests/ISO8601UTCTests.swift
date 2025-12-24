import XCTest

@testable import RCKit

final class ISO8601UTCTests: XCTestCase {
    func testFormatsWithFractionalSeconds() {
        let date = Date(timeIntervalSince1970: 0)
        let text = ISO8601UTC.string(from: date)
        XCTAssertEqual(text, "1970-01-01T00:00:00.000Z")
    }

    func testFormatsWithoutFractionalSeconds() {
        let date = Date(timeIntervalSince1970: 0)
        let text = ISO8601UTC.string(from: date, includeFractionalSeconds: false)
        XCTAssertEqual(text, "1970-01-01T00:00:00Z")
    }

    func testParsesFractionalAndNonFractional() {
        let fractional = "2025-12-24T02:18:50.123Z"
        let nonFractional = "2025-12-24T02:18:50Z"

        let fractionalDate = ISO8601UTC.date(from: fractional)
        let nonFractionalDate = ISO8601UTC.date(from: nonFractional)

        XCTAssertNotNil(fractionalDate)
        XCTAssertNotNil(nonFractionalDate)
        guard let nonFractionalDate else {
            XCTFail("Expected non-fractional date to parse")
            return
        }
        XCTAssertEqual(
            ISO8601UTC.string(from: nonFractionalDate, includeFractionalSeconds: false),
            nonFractional
        )
    }

    func testReturnsNilForInvalidInput() {
        XCTAssertNil(ISO8601UTC.date(from: "not-a-date"))
        XCTAssertNil(ISO8601UTC.date(from: nil))
        XCTAssertNil(ISO8601UTC.string(from: nil))
    }
}
