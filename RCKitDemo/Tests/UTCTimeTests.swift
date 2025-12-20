import XCTest
@testable import RCKitDemo

final class UTCTimeTests: XCTestCase {
  func testISO8601UsesUTC() {
    let date = Date(timeIntervalSince1970: 0)
    let formatted = UTCDateFormatter.iso8601String(from: date)
    XCTAssertEqual(formatted, "1970-01-01T00:00:00.000Z")
  }
}
