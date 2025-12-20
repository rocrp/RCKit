//
//  DateTests.swift
//
//
//  Created by RoCry on 2024/1/16.
//

import XCTest

@testable import RCKit

final class DateTests: XCTestCase {
  func testBasic() throws {
    let now = Date()

    XCTAssertEqual(now.addingTimeInterval(-100).relativeShortString(comparing: now), "1m")
    XCTAssertEqual(now.addingTimeInterval(3600).relativeShortString(comparing: now), "-1h")
  }
}
