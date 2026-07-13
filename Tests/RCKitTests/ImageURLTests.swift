//
//  ImageURLTests.swift
//
//
//  Created by RoCry on 2024/1/18.
//

import XCTest

@testable import RCKit

final class ImageURLTests: XCTestCase {
    func testUnsplashWidthStrategy() throws {
        let source = try XCTUnwrap(URL(string: "https://images.unsplash.com/photo-1705255620917-fcc1300ca0fa"))
        let adjusted = try XCTUnwrap(source.adjustedImageSize(.width(100)))
        XCTAssertEqual(
            adjusted.absoluteString,
            "https://images.unsplash.com/photo-1705255620917-fcc1300ca0fa?w=100&q=80&auto=format&fit=crop"
        )
    }

    func testUnsplashHeightStrategyReplacesExistingDimensions() throws {
        let source = try XCTUnwrap(
            URL(
                string:
                    "https://images.unsplash.com/photo-1705388364884-747aa0687da2?q=80&w=4000&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
            )
        )
        let adjusted = try XCTUnwrap(source.adjustedImageSize(.height(100)))
        XCTAssertEqual(
            adjusted.queryString(sort: true),
            "auto=format&fit=crop&h=100&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA==&ixlib=rb-4.0.3&q=80"
        )
    }

    func testUnsplashSizeStrategySetsAllStandardParameters() throws {
        let source = try XCTUnwrap(URL(string: "https://images.unsplash.com/photo"))
        let adjusted = try XCTUnwrap(source.adjustedImageSize(.size(width: 640, height: 480)))

        XCTAssertEqual(adjusted.queryString(sort: true), "auto=format&fit=crop&h=480&q=80&w=640")
    }

    func testUnsupportedOrHostlessURLReturnsNil() throws {
        let unsupported = try XCTUnwrap(URL(string: "https://example.com/image.jpg"))
        let hostless = try XCTUnwrap(URL(string: "/image.jpg"))

        XCTAssertNil(unsupported.adjustedImageSize(.width(100)))
        XCTAssertNil(hostless.adjustedImageSize(.width(100)))
    }
}
