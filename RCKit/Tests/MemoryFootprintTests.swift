//
//  MemoryFootprintTests.swift
//
//
//  Created by RoCry on 2024/5/1.
//

import XCTest

@testable import RCKit

final class MemoryFootprintTests: XCTestCase {
  func testMemoryUsage() {
    let memoryResult = MemoryFootprint.getMemoryUsage()

    switch memoryResult {
    case .success(let usage):
      XCTAssertGreaterThan(usage.residentMemory, 0, "Resident memory should be greater than 0")
      XCTAssertGreaterThanOrEqual(
        usage.total, usage.residentMemory,
        "Total memory should be at least as large as resident memory")

      let formattedString = usage.formattedString()
      XCTAssertFalse(formattedString.isEmpty, "Formatted memory string should not be empty")

    case .failure(let error):
      XCTFail("Memory measurement failed with error: \(error.localizedDescription)")
    }
  }

  func testMemoryFormatting() {
    let bytesValue: UInt64 = 1024
    XCTAssertEqual(bytesValue.formattedMemorySize(unit: .bytes), "1024 bytes")
    XCTAssertEqual(bytesValue.formattedMemorySize(unit: .kilobytes), "1.00 KB")

    let mbValue: UInt64 = 1024 * 1024 * 5  // 5 MB
    XCTAssertEqual(mbValue.formattedMemorySize(unit: .megabytes), "5.00 MB")

    let gbValue: UInt64 = 1024 * 1024 * 1024 * 2  // 2 GB
    XCTAssertEqual(gbValue.formattedMemorySize(unit: .gigabytes), "2.00 GB")
  }

  func testFormattedMemoryUsage() throws {
    let formatted = try MemoryFootprint.getFormattedMemoryUsage()
    XCTAssertFalse(formatted.isEmpty, "Formatted memory usage should not be empty")
  }
}
