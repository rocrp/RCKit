//
//  RandomTests.swift
//
//
//  Created by RoCry on 2024/1/24.
//

import XCTest

@testable import RCKit

// Simplified test suite focusing on basic functionality
final class RandomTests: XCTestCase {
    func testRandomGeneration() {
        // Test String random
        let string = String.random(size: 5)
        XCTAssertEqual(string.count, 5)

        // Test Character random
        let char = Character.random()
        XCTAssertNotNil(char)

        // Test random alphanumeric
        let alphanum = String.randomAlphanumeric(size: 8)
        XCTAssertEqual(alphanum.count, 8)

        // Test random hex
        let hex = String.randomHex(size: 6)
        XCTAssertEqual(hex.count, 6)
        XCTAssertTrue(hex.allSatisfy { "0123456789abcdef".contains($0) })
    }

    func testDataRandom() {
        // Test Data random
        let data = Data.random(size: 10)
        XCTAssertEqual(data.count, 10)
    }

    func testUUIDRandom() {
        // Test UUID random
        let uuid = UUID.random()
        XCTAssertNotNil(uuid)
    }
}
