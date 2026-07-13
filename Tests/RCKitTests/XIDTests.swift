//
//  XIDTests.swift
//
//
//  Created by RoCry on 2024/2/8.
//

import XCTest

@testable import RCKit

final class XIDTests: XCTestCase {
    func testXIDGeneration() throws {
        let xid1 = try XID.generate()
        let xid2 = try XID.generate()
        XCTAssertEqual(xid1.count, 20, "XID should be exactly 20 characters")
        XCTAssertEqual(xid2.count, 20, "XID should be exactly 20 characters")
        XCTAssertNotEqual(xid1, xid2, "Two sequentially generated XIDs should not be equal")
    }

    func testXIDWithSpecificDate() throws {
        let date1 = Date(timeIntervalSince1970: 1_609_459_200)  // 2021-01-01
        let date2 = Date(timeIntervalSince1970: 1_640_995_200)  // 2022-01-01

        let xid1 = try XID.generate(date: date1)
        let xid2 = try XID.generate(date: date2)

        XCTAssertEqual(xid1.count, 20, "XID should be exactly 20 characters")
        XCTAssertEqual(xid2.count, 20, "XID should be exactly 20 characters")
        XCTAssertNotEqual(xid1, xid2, "XIDs with different dates should not be equal")
    }

    func testGoXIDReferenceVectorByteLayoutAndEncoding() {
        let encoded = XID.encode(
            timestamp: 1_300_816_219,
            machineID: [0x60, 0xf4, 0x86],
            processID: 0xe428,
            counter: 0x41_2d_c9
        )

        XCTAssertEqual(encoded, "9m4e2mr0ui3e8a215n4g")
    }

    func testXIDErrors() {
        // Test with date that exceeds UInt32.max
        let farFutureDate = Date(timeIntervalSince1970: TimeInterval(UInt32.max) + 1)
        XCTAssertThrowsError(
            try XID.generate(date: farFutureDate),
            "Should throw an error for date overflow"
        ) { error in
            XCTAssertTrue(error is XID.Error, "Error should be of type XID.Error")
            if let xidError = error as? XID.Error {
                XCTAssertEqual(xidError, XID.Error.dateOverflow, "Error should be dateOverflow")
            }
        }
    }
}
