import XCTest

@testable import RCKit

final class RCKitLogTests: XCTestCase {
  func testLog() {
    RCKit.log.info("log smoke test")
    RCKit.log.printDebugInfo()
  }
}
