//
//  TimeInterval.swift
//
//
//  Created by RoCry on 2024/1/16.
//

import XCTest

@testable import RCKit

final class TimeIntervalTests: XCTestCase {
  func testBasic() throws {
    XCTAssertEqual(TimeInterval(10).shortString, "10s")
    XCTAssertEqual(TimeInterval(3601).shortString, "1h")
  }
}
