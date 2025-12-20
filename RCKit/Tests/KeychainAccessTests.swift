//
//  KeychainAccessTests.swift
//
//
//  Created by RoCry on 2024/5/1.
//

import XCTest

@testable import RCKit

final class KeychainAccessTests: XCTestCase {
  // Sample data structure for testing
  private struct TestUser: Codable, Equatable {
    let id: String
    let name: String
    let isActive: Bool
  }

  // Test keychain instance
  private var keychain: KeychainAccess!

  // Service name used for tests - unique to avoid conflicts
  private let testService = "com.rocry.KeychainAccessTests.\(UUID().uuidString)"

  // Common keys used in tests
  private let stringKey = "test_string"
  private let boolKey = "test_bool"
  private let dataKey = "test_data"
  private let objectKey = "test_object"

  override func setUp() {
    super.setUp()
    keychain = KeychainAccess(service: testService)

    // Clean up any leftover data from previous test runs
    _ = keychain.delete(for: stringKey)
    _ = keychain.delete(for: boolKey)
    _ = keychain.delete(for: dataKey)
    _ = keychain.delete(for: objectKey)
  }

  override func tearDown() {
    // Clean up after each test
    _ = keychain.delete(for: stringKey)
    _ = keychain.delete(for: boolKey)
    _ = keychain.delete(for: dataKey)
    _ = keychain.delete(for: objectKey)

    keychain = nil
    super.tearDown()
  }

  func testStringOperations() {
    // Test that the key doesn't exist initially
    XCTAssertFalse(keychain.exists(for: stringKey))

    // Test storing a string
    let testString = "Hello, Keychain!"
    let setResult = keychain.set(testString, for: stringKey)
    if case .failure(let error) = setResult {
      XCTFail("Failed to set string value: \(error)")
    }

    // Test that the key now exists
    XCTAssertTrue(keychain.exists(for: stringKey))

    // Test retrieving the string
    let getResult = keychain.getString(for: stringKey)
    switch getResult {
    case .success(let retrievedString):
      XCTAssertEqual(retrievedString, testString)
    case .failure(let error):
      XCTFail("Failed to get string value: \(error)")
    }

    // Test updating the string
    let updatedString = "Updated String"
    _ = keychain.set(updatedString, for: stringKey)

    let updatedResult = keychain.getString(for: stringKey)
    switch updatedResult {
    case .success(let retrievedString):
      XCTAssertEqual(retrievedString, updatedString)
    case .failure(let error):
      XCTFail("Failed to get updated string value: \(error)")
    }

    // Test deleting the string
    let deleteResult = keychain.delete(for: stringKey)
    if case .failure(let error) = deleteResult {
      XCTFail("Failed to delete string value: \(error)")
    }

    XCTAssertFalse(keychain.exists(for: stringKey))
  }

  func testBooleanOperations() {
    // Test storing a boolean
    XCTAssertFalse(keychain.exists(for: boolKey))

    let setBoolResult = keychain.set(true, for: boolKey)
    if case .failure(let error) = setBoolResult {
      XCTFail("Failed to set boolean value: \(error)")
    }

    // Test that the key now exists
    XCTAssertTrue(keychain.exists(for: boolKey))

    // Test retrieving the boolean
    let getBoolResult = keychain.getBool(for: boolKey)
    switch getBoolResult {
    case .success(let retrievedBool):
      XCTAssertTrue(retrievedBool)
    case .failure(let error):
      XCTFail("Failed to get boolean value: \(error)")
    }

    // Test updating the boolean
    _ = keychain.set(false, for: boolKey)

    let updatedBoolResult = keychain.getBool(for: boolKey)
    switch updatedBoolResult {
    case .success(let retrievedBool):
      XCTAssertFalse(retrievedBool)
    case .failure(let error):
      XCTFail("Failed to get updated boolean value: \(error)")
    }
  }

  func testDataOperations() {
    // Test storing data
    let testData = "Test Data".data(using: .utf8)!

    let setDataResult = keychain.set(testData, for: dataKey)
    if case .failure(let error) = setDataResult {
      XCTFail("Failed to set data value: \(error)")
    }

    // Test retrieving the data
    let getDataResult = keychain.getData(for: dataKey)
    switch getDataResult {
    case .success(let retrievedData):
      XCTAssertEqual(retrievedData, testData)
    case .failure(let error):
      XCTFail("Failed to get data value: \(error)")
    }
  }

  func testCodableOperations() {
    // Create a test user
    let testUser = TestUser(id: "123", name: "Test User", isActive: true)

    // Store the user
    let setUserResult = keychain.set(testUser, for: objectKey)
    if case .failure(let error) = setUserResult {
      XCTFail("Failed to set codable object: \(error)")
    }

    // Retrieve the user
    let getUserResult = keychain.getCodable(for: objectKey, as: TestUser.self)
    switch getUserResult {
    case .success(let retrievedUser):
      XCTAssertEqual(retrievedUser, testUser)
    case .failure(let error):
      XCTFail("Failed to get codable object: \(error)")
    }
  }

  func testNonExistentItem() {
    // Try to get non-existent data
    let getDataResult = keychain.getData(for: "nonexistent")

    // Test that result is failure
    switch getDataResult {
    case .success:
      XCTFail("Should not successfully retrieve non-existent data")
    case .failure(let error):
      XCTAssertEqual(error, .itemNotFound)
    }
  }
}
