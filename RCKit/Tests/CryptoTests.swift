//
//  CryptoTests.swift
//
//
//  Created by RoCry on 2024/2/8.
//

import XCTest

@testable import RCKit

final class CryptoTests: XCTestCase {
  // Test data values
  let testString = "Hello, world!"

  func testSHA256() {
    XCTAssertEqual(
      "hello".sha256, "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
    XCTAssertEqual(
      testString.sha256, "315f5bdb76d078c43b8ac0064e4a0164612b1fce77c869345bfc94c75894edd3")
  }

  func testSHA512() {
    XCTAssertEqual(
      testString.sha512,
      "c1527cd893c124773d811911970c8fe6e857d6df5dc9226bd8a160614c0cd963a4ddea2b94bb7d36021ef9d865d5cea294a82dd49a0bb269f51f6e7a57f79421"
    )
  }

  func testBase64Encoding() {
    let base64Encoded = testString.base64Encoded
    XCTAssertEqual(base64Encoded, "SGVsbG8sIHdvcmxkIQ==")
  }

  func testBase64Decoding() {
    let encoded = "SGVsbG8sIHdvcmxkIQ=="
    let decoded = encoded.base64Decoded
    XCTAssertEqual(decoded, "Hello, world!")
  }

  func testDataHashing() {
    let data = Data(testString.utf8)

    XCTAssertEqual(data.digest(using: .sha256), testString.sha256)
    XCTAssertEqual(data.digest(using: .sha512), testString.sha512)
  }
}
