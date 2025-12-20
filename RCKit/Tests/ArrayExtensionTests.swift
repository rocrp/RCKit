//
//  ArrayExtensionTests.swift
//
//
//  Created by RoCry on 2024/5/1.
//

import XCTest

@testable import RCKit

final class ArrayExtensionTests: XCTestCase {

  // Test arrays
  let intArray = [1, 2, 3, 4, 5]
  let stringArray = ["apple", "banana", "cherry", "date", "elderberry"]
  let duplicateArray = [1, 2, 2, 3, 3, 3, 4, 5, 5]

  // MARK: - Shuffle Tests

  func testShuffled() {
    let original = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    let shuffled = original.shuffled()

    // Verify same elements are present
    XCTAssertEqual(original.sorted(), shuffled.sorted())

    // It's technically possible but extremely unlikely that a shuffle would result in the same order
    // So if we perform multiple shuffles, at least one should be different
    var atLeastOneDifferent = false
    for _ in 1...5 {
      if original != original.shuffled() {
        atLeastOneDifferent = true
        break
      }
    }
    XCTAssertTrue(atLeastOneDifferent)
  }

  func testShuffle() {
    var array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    let original = array

    array.shuffle()

    // Verify same elements are present
    XCTAssertEqual(original.sorted(), array.sorted())

    // Multiple shuffles test
    var atLeastOneDifferent = false
    for _ in 1...5 {
      var testArray = original
      testArray.shuffle()
      if testArray != original {
        atLeastOneDifferent = true
        break
      }
    }
    XCTAssertTrue(atLeastOneDifferent)
  }

  // MARK: - Elements At Indices Tests

  func testElementsAtIndices() {
    // Normal case
    XCTAssertEqual(intArray.elements(at: [0, 2, 4]), [1, 3, 5])

    // Empty indices
    XCTAssertEqual([Int]().elements(at: []), [])

    // Duplicate indices should return duplicate elements
    XCTAssertEqual(intArray.elements(at: [0, 0, 1]), [1, 1, 2])
  }

  // MARK: - Removing Duplicates Tests

  func testRemovingDuplicatesByComparison() {
    let result = duplicateArray.removingDuplicates { $0 == $1 }
    XCTAssertEqual(result, [1, 2, 3, 4, 5])
  }

  func testRemovingDuplicatesEquatable() {
    let result = duplicateArray.removingDuplicates()
    XCTAssertEqual(result, [1, 2, 3, 4, 5])
  }

  func testRemovingDuplicatesHashable() {
    let result = duplicateArray.removingDuplicatesViaSet()
    XCTAssertEqual(result, [1, 2, 3, 4, 5])

    // String array
    let duplicateStrings = ["apple", "banana", "apple", "cherry", "banana"]
    let uniqueStrings = duplicateStrings.removingDuplicatesViaSet()
    XCTAssertEqual(uniqueStrings, ["apple", "banana", "cherry"])
  }

  // MARK: - Chunking Tests

  func testChunked() {
    // Normal case
    XCTAssertEqual(intArray.chunked(into: 2), [[1, 2], [3, 4], [5]])

    // Chunk size equal to array size
    XCTAssertEqual(intArray.chunked(into: 5), [[1, 2, 3, 4, 5]])

    // Chunk size larger than array size
    XCTAssertEqual(intArray.chunked(into: 10), [[1, 2, 3, 4, 5]])

    // Chunk size of 1
    XCTAssertEqual(intArray.chunked(into: 1), [[1], [2], [3], [4], [5]])

    // Empty array
    XCTAssertEqual([Int]().chunked(into: 2), [])
  }

  // MARK: - Divided Tests

  func testDivided() {
    // Divide by even/odd
    let (evens, odds) = intArray.divided { $0 % 2 == 0 }
    XCTAssertEqual(evens, [2, 4])
    XCTAssertEqual(odds, [1, 3, 5])

    // Divide by length
    let (short, long) = stringArray.divided { $0.count <= 5 }
    XCTAssertEqual(short, ["apple", "date"])
    XCTAssertEqual(long, ["banana", "cherry", "elderberry"])

    // All elements satisfy predicate
    let (allPassed, allFailed) = intArray.divided { $0 > 0 }
    XCTAssertEqual(allPassed, intArray)
    XCTAssertEqual(allFailed, [])

    // No elements satisfy predicate
    let (nonePassed, noneFailed) = intArray.divided { $0 > 10 }
    XCTAssertEqual(nonePassed, [])
    XCTAssertEqual(noneFailed, intArray)
  }

  // MARK: - Prefix and Suffix Tests

  func testTakePrefix() {
    XCTAssertEqual(intArray.takePrefix(3), [1, 2, 3])
    XCTAssertEqual(intArray.takePrefix(0), [])
    XCTAssertEqual(intArray.takePrefix(10), intArray)
  }

  func testTakeSuffix() {
    XCTAssertEqual(intArray.takeSuffix(3), [3, 4, 5])
    XCTAssertEqual(intArray.takeSuffix(0), [])
    XCTAssertEqual(intArray.takeSuffix(10), intArray)
  }

  // MARK: - First Where Tests

  func testFirstWhere() {
    XCTAssertEqual(intArray.first { $0 > 3 }, 4)
    XCTAssertEqual(stringArray.first { $0.hasPrefix("b") }, "banana")
    XCTAssertNil(intArray.first { $0 > 10 })
    XCTAssertNil([Int]().first { $0 > 0 })
  }

  // MARK: - Filter Tests

  func testFilter() {
    XCTAssertEqual(intArray.filter { $0 % 2 == 0 }, [2, 4])
    XCTAssertEqual(stringArray.filter { $0.count > 5 }, ["banana", "cherry", "elderberry"])
    XCTAssertEqual(intArray.filter { $0 > 10 }, [])
    XCTAssertEqual([Int]().filter { $0 > 0 }, [])
  }

  // MARK: - Map Tests

  func testMap() {
    XCTAssertEqual(intArray.map { $0 * 2 }, [2, 4, 6, 8, 10])
    XCTAssertEqual(stringArray.map { $0.count }, [5, 6, 6, 4, 10])
    XCTAssertEqual([Int]().map { $0 * 2 }, [])
  }

  // MARK: - CompactMap Tests

  func testCompactMap() {
    let mixedArray = ["1", "two", "3", "four", "5"]
    XCTAssertEqual(mixedArray.compactMap { Int($0) }, [1, 3, 5])
    XCTAssertEqual(stringArray.compactMap { $0.first }, ["a", "b", "c", "d", "e"])
    XCTAssertEqual([String]().compactMap { Int($0) }, [])
  }

  // MARK: - Binary Search Tests

  func testBinarySearchWithComparison() {
    let sortedArray = [10, 20, 30, 40, 50, 60, 70, 80, 90]

    // Found
    XCTAssertEqual(
      sortedArray.binarySearch(for: 50) { (a, b) -> ComparisonResult in
        if a < b {
          return .orderedAscending
        } else if a > b {
          return .orderedDescending
        } else {
          return .orderedSame
        }
      }, 4)

    // Not found
    XCTAssertNil(
      sortedArray.binarySearch(for: 55) { (a, b) -> ComparisonResult in
        if a < b {
          return .orderedAscending
        } else if a > b {
          return .orderedDescending
        } else {
          return .orderedSame
        }
      })

    // Empty array
    XCTAssertNil(
      [Int]().binarySearch(for: 10) { (a, b) -> ComparisonResult in
        if a < b {
          return .orderedAscending
        } else if a > b {
          return .orderedDescending
        } else {
          return .orderedSame
        }
      })
  }

  func testBinarySearch() {
    let sortedArray = [10, 20, 30, 40, 50, 60, 70, 80, 90]

    // Found
    XCTAssertEqual(sortedArray.binarySearch(for: 50), 4)

    // Not found
    XCTAssertNil(sortedArray.binarySearch(for: 55))

    // Empty array
    XCTAssertNil([Int]().binarySearch(for: 10))

    // String array
    let sortedStrings = ["apple", "banana", "cherry", "date", "elderberry"]
    XCTAssertEqual(sortedStrings.binarySearch(for: "cherry"), 2)
    XCTAssertNil(sortedStrings.binarySearch(for: "fig"))
  }

  // MARK: - Removal Tests

  func testRemovingAt() {
    XCTAssertEqual(intArray.removing(at: 2), [1, 2, 4, 5])
    XCTAssertEqual(intArray.removing(at: 0), [2, 3, 4, 5])
    XCTAssertEqual(intArray.removing(at: 4), [1, 2, 3, 4])
  }

  func testReplacing() {
    XCTAssertEqual(intArray.replacing(at: 2, with: 10), [1, 2, 10, 4, 5])
    XCTAssertEqual(intArray.replacing(at: 0, with: 10), [10, 2, 3, 4, 5])
    XCTAssertEqual(intArray.replacing(at: 4, with: 10), [1, 2, 3, 4, 10])
  }

  func testInserting() {
    XCTAssertEqual(intArray.inserting(10, at: 2), [1, 2, 10, 3, 4, 5])
    XCTAssertEqual(intArray.inserting(10, at: 0), [10, 1, 2, 3, 4, 5])
    XCTAssertEqual(intArray.inserting(10, at: 5), [1, 2, 3, 4, 5, 10])
  }

  // MARK: - Random Element Tests

  func testRandomElement() {
    // Not deterministic, but we can test that it returns an element from the array
    for _ in 1...10 {
      if let element = intArray.randomElement() {
        XCTAssertTrue(intArray.contains(element))
      } else {
        XCTFail("randomElement should not return nil for non-empty array")
      }
    }

    // Empty array
    XCTAssertNil([Int]().randomElement())
  }

  // MARK: - Removing Element Tests

  func testRemoving() {
    XCTAssertEqual(intArray.removing(3), [1, 2, 4, 5])
    XCTAssertEqual(intArray.removing(1), [2, 3, 4, 5])

    // Element not in array
    XCTAssertEqual(intArray.removing(10), intArray)

    // Duplicate elements (should remove only first occurrence)
    XCTAssertEqual(duplicateArray.removing(3), [1, 2, 2, 3, 3, 4, 5, 5])
  }

  func testRemovingAll() {
    XCTAssertEqual(duplicateArray.removingAll(of: 3), [1, 2, 2, 4, 5, 5])
    XCTAssertEqual(duplicateArray.removingAll(of: 1), [2, 2, 3, 3, 3, 4, 5, 5])

    // Element not in array
    XCTAssertEqual(intArray.removingAll(of: 10), intArray)
  }

  // MARK: - Dictionary Conversion Tests

  func testToDictionaryWithKeyAndValue() {
    let dictionary = intArray.toDictionary(
      keyForValue: { "key\($0)" },
      valueForKey: { $0 * 10 }
    )

    XCTAssertEqual(dictionary.count, 5)
    XCTAssertEqual(dictionary["key1"], 10)
    XCTAssertEqual(dictionary["key2"], 20)
    XCTAssertEqual(dictionary["key3"], 30)
    XCTAssertEqual(dictionary["key4"], 40)
    XCTAssertEqual(dictionary["key5"], 50)
  }

  func testToDictionary() {
    let dictionary = intArray.toDictionary { "key\($0)" }

    XCTAssertEqual(dictionary.count, 5)
    XCTAssertEqual(dictionary["key1"], 1)
    XCTAssertEqual(dictionary["key2"], 2)
    XCTAssertEqual(dictionary["key3"], 3)
    XCTAssertEqual(dictionary["key4"], 4)
    XCTAssertEqual(dictionary["key5"], 5)
  }

  // MARK: - Indices Tests

  func testIndices() {
    XCTAssertEqual(intArray.indices(of: 3), [2])
    XCTAssertEqual(duplicateArray.indices(of: 3), [3, 4, 5])
    XCTAssertEqual(duplicateArray.indices(of: 5), [7, 8])

    // Element not in array
    XCTAssertEqual(intArray.indices(of: 10), [])

    // Empty array
    XCTAssertEqual([Int]().indices(of: 1), [])
  }
}
