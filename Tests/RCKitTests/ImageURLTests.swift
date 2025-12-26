//
//  ImageURLTests.swift
//
//
//  Created by RoCry on 2024/1/18.
//

import XCTest

@testable import RCKit

final class ImageURLTests: XCTestCase {
    func testImageURL() throws {
        var a = URL(string: "https://images.unsplash.com/photo-1705255620917-fcc1300ca0fa")!
        a.adjustImageSize(.width(100))
        XCTAssertEqual(
            a.absoluteString,
            "https://images.unsplash.com/photo-1705255620917-fcc1300ca0fa?w=100&q=80&auto=format&fit=crop"
        )

        var b = URL(
            string:
                "https://images.unsplash.com/photo-1705388364884-747aa0687da2?q=80&w=4000&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
        )!
        b.adjustImageSize(.height(100))
        XCTAssertEqual(
            b.queryString(sort: true),
            "auto=format&fit=crop&h=100&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA==&ixlib=rb-4.0.3&q=80"
        )
    }
}
