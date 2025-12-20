import XCTest

@testable import RCKit

final class RCKitLogTests: XCTestCase {
  func testBootstrapAndLog() {
    RCKitLog.bootstrap()
    RCKit.log.info("log smoke test")
    RCKit.log.printDebugInfo()
  }
}
