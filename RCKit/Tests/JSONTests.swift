//
//  JSONTests.swift
//
//
//  Created by RoCry on 2024/5/1.
//

import XCTest

@testable import RCKit

final class JSONTests: XCTestCase {
  // Sample data structures for testing
  private struct Person: Codable, Equatable {
    let name: String
    let age: Int
    let email: String?
  }

  private struct Address: Codable, Equatable {
    let street: String
    let city: String
    let zipCode: String
  }

  private struct PersonWithAddress: Codable, Equatable {
    let name: String
    let age: Int
    let address: Address
    let phoneNumbers: [String]
  }

  private let sampleJSON = """
    {
        "name": "John Doe",
        "age": 30,
        "address": {
            "street": "123 Main St",
            "city": "San Francisco",
            "zipCode": "94105"
        },
        "phoneNumbers": [
            "555-1234",
            "555-5678"
        ]
    }
    """

  private let sampleJSONArray = """
    [
        {
            "name": "John Doe",
            "age": 30
        },
        {
            "name": "Jane Smith",
            "age": 28
        }
    ]
    """

  func testDataDecode() throws {
    guard let jsonData = sampleJSON.data(using: .utf8) else {
      XCTFail("Failed to create JSON data")
      return
    }

    let person = try JSONDecoder().decode(PersonWithAddress.self, from: jsonData)
    XCTAssertEqual(person.name, "John Doe")
    XCTAssertEqual(person.age, 30)
    XCTAssertEqual(person.address.street, "123 Main St")
    XCTAssertEqual(person.address.city, "San Francisco")
    XCTAssertEqual(person.address.zipCode, "94105")
    XCTAssertEqual(person.phoneNumbers, ["555-1234", "555-5678"])
  }

  func testDataDecodeArray() throws {
    guard let jsonData = sampleJSONArray.data(using: .utf8) else {
      XCTFail("Failed to create JSON array data")
      return
    }

    let people = try JSONDecoder().decode([Person].self, from: jsonData)
    XCTAssertEqual(people.count, 2)
    XCTAssertEqual(people[0].name, "John Doe")
    XCTAssertEqual(people[0].age, 30)
    XCTAssertEqual(people[1].name, "Jane Smith")
    XCTAssertEqual(people[1].age, 28)
  }

  func testEncodableToJSONData() throws {
    let person = Person(name: "John Doe", age: 30, email: "john@example.com")

    let jsonData = try JSONEncoder().encode(person)
    XCTAssertNotNil(jsonData)

    // Verify by decoding back
    let decoded = try JSONDecoder().decode(Person.self, from: jsonData)
    XCTAssertEqual(decoded, person)
  }

  func testEncodableToJSONString() throws {
    let person = Person(name: "John Doe", age: 30, email: "john@example.com")

    let jsonData = try JSONEncoder().encode(person)
    let jsonString = String(data: jsonData, encoding: .utf8)!
    XCTAssertTrue(isValidJSON(jsonString))
    XCTAssertTrue(jsonString.contains("John Doe"))
    XCTAssertTrue(jsonString.contains("john@example.com"))

    // Test pretty printed
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let prettyData = try encoder.encode(person)
    let prettyString = String(data: prettyData, encoding: .utf8)!
    XCTAssertTrue(isValidJSON(prettyString))
    XCTAssertTrue(prettyString.contains("\n"))  // Should have newlines for pretty print
  }

  func testJSONValidation() {
    XCTAssertTrue(isValidJSON(sampleJSON))
    XCTAssertTrue(isValidJSON(sampleJSONArray))
    XCTAssertFalse(isValidJSON("Invalid JSON"))
    XCTAssertFalse(isValidJSON("{incomplete"))

    guard let validData = sampleJSON.data(using: .utf8) else {
      XCTFail("Failed to create data")
      return
    }
    XCTAssertTrue(isValidJSON(validData))

    let invalidData = "Invalid JSON".data(using: .utf8)!
    XCTAssertFalse(isValidJSON(invalidData))
  }

  func testRoundTrip() throws {
    let original = Person(name: "Alice", age: 25, email: nil)

    // Encode to JSON data
    let jsonData = try JSONEncoder().encode(original)

    // Decode back
    let decoded = try JSONDecoder().decode(Person.self, from: jsonData)

    XCTAssertEqual(original, decoded)
  }

  func testComplexStructure() throws {
    let address = Address(street: "456 Oak Ave", city: "Boston", zipCode: "02101")
    let person = PersonWithAddress(
      name: "Bob Smith",
      age: 35,
      address: address,
      phoneNumbers: ["617-1234", "617-5678"]
    )

    // Encode to JSON string
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let jsonData = try encoder.encode(person)
    let jsonString = String(data: jsonData, encoding: .utf8)!
    XCTAssertTrue(isValidJSON(jsonString))

    // Decode back from string
    guard let data = jsonString.data(using: .utf8) else {
      XCTFail("Failed to create data from JSON string")
      return
    }

    let decoded = try JSONDecoder().decode(PersonWithAddress.self, from: data)
    XCTAssertEqual(person, decoded)
  }

  func testJSONCodingUTC() throws {
    struct Timestamped: Codable, Equatable {
      let id: String
      let createdAt: Date
    }

    let date = Date(timeIntervalSince1970: 1_734_000_000.123)
    let payload = Timestamped(id: "demo", createdAt: date)

    let encoder = JSONCoding.makeEncoder()
    let data = try encoder.encode(payload)

    let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let encodedDate = jsonObject?["createdAt"] as? String
    XCTAssertNotNil(encodedDate)
    XCTAssertTrue(encodedDate?.hasSuffix("Z") ?? false)

    let decoder = JSONCoding.makeDecoder()
    let decoded = try decoder.decode(Timestamped.self, from: data)
    XCTAssertEqual(decoded.id, payload.id)
    XCTAssertEqual(
      decoded.createdAt.timeIntervalSince1970, payload.createdAt.timeIntervalSince1970,
      accuracy: 0.001)
  }

  // MARK: - Helper Methods

  private func isValidJSON(_ string: String) -> Bool {
    guard let data = string.data(using: .utf8) else { return false }
    return isValidJSON(data)
  }

  private func isValidJSON(_ data: Data) -> Bool {
    do {
      _ = try JSONSerialization.jsonObject(with: data, options: [])
      return true
    } catch {
      return false
    }
  }
}
