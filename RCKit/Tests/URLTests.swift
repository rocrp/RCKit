//
//  URLTest.swift
//
//
//  Created by RoCry on 2024/1/18.
//

import XCTest

@testable import RCKit

final class URLTest: XCTestCase {
  func testURL() throws {
    var u1 = URL(string: "https://rocry.com")!
    XCTAssertEqual(u1.absoluteString, "https://rocry.com")

    u1["a"] = "b"
    XCTAssertEqual(u1.absoluteString, "https://rocry.com?a=b")
    u1["a"] = "b"
    XCTAssertEqual(u1.absoluteString, "https://rocry.com?a=b")
    u1["a"] = "c"
    XCTAssertEqual(u1.absoluteString, "https://rocry.com?a=c")
    u1["a"] = nil
    XCTAssertEqual(u1.absoluteString, "https://rocry.com")

    var u2 = URL(string: "https://rocry.com?a=b")!
    XCTAssertEqual(u2.absoluteString, "https://rocry.com?a=b")
    u2["e"] = "f"
    u2["c"] = "d"
    XCTAssertEqual(u2.absoluteString, "https://rocry.com?a=b&e=f&c=d")
    XCTAssertEqual(u2.queryString(), "a=b&e=f&c=d")
    XCTAssertEqual(u2.queryString(sort: true), "a=b&c=d&e=f")
  }
}
