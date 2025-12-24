//
//  Array+Extension.swift
//
//
//  Created by RoCry on 2024/5/1.
//

import Foundation

extension Array {

    /// Returns a new array containing the elements at the specified indices
    /// - Parameter indices: The indices to select
    /// - Returns: An array with the elements at the specified indices
    /// - Precondition: All indices must be within bounds.
    public func elements(at indices: [Int]) -> [Element] {
        guard !indices.isEmpty else { return [] }
        let invalid = indices.filter { $0 < 0 || $0 >= count }
        precondition(
            invalid.isEmpty,
            "Array.elements(at:) invalid indices \(invalid) for count \(count)"
        )
        return indices.map { self[$0] }
    }

    /// Returns a new array with duplicate elements removed, preserving the original order
    /// - Parameter compare: A closure that returns true if two elements are considered equal
    /// - Returns: An array with duplicate elements removed
    public func removingDuplicates(by compare: (Element, Element) -> Bool) -> [Element] {
        var result = [Element]()

        for element in self {
            if !result.contains(where: { compare(element, $0) }) {
                result.append(element)
            }
        }

        return result
    }

    /// Returns a new array with duplicate elements removed, preserving the original order
    /// Only applicable to arrays with elements that conform to Equatable
    /// - Returns: An array with duplicate elements removed
    public func removingDuplicates() -> [Element] where Element: Equatable {
        return removingDuplicates(by: ==)
    }

    /// Returns a new array with duplicate elements removed, preserving the original order
    /// Only applicable to arrays with elements that conform to Hashable
    /// - Returns: An array with duplicate elements removed
    public func removingDuplicatesViaSet() -> [Element] where Element: Hashable {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }

    /// Returns a new array with the elements grouped into chunks of the specified size
    /// - Parameter size: The size of each chunk
    /// - Returns: An array of arrays, each containing at most `size` elements
    /// - Precondition: size must be > 0
    public func chunked(into size: Int) -> [[Element]] {
        precondition(size > 0, "Array.chunked(into:) size must be > 0")
        guard !isEmpty else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }

    /// Returns a new array with the elements that satisfy the given predicate, and another array
    /// with the elements that don't.
    /// - Parameter isIncluded: A closure that takes an element and returns a Boolean value indicating
    ///   whether the element should be included in the first array.
    /// - Returns: A tuple of two arrays, the first containing the elements for which `isIncluded`
    ///   returns `true`, and the second containing the elements for which `isIncluded` returns `false`.
    public func divided(by isIncluded: (Element) -> Bool) -> (
        included: [Element], excluded: [Element]
    ) {
        var included = [Element]()
        var excluded = [Element]()

        for element in self {
            if isIncluded(element) {
                included.append(element)
            } else {
                excluded.append(element)
            }
        }

        return (included, excluded)
    }

    /// Returns a new array containing the first `n` elements.
    /// - Parameter n: The maximum number of elements to return.
    /// - Returns: An array containing at most the first `n` elements.
    /// - Precondition: n must be >= 0
    public func takePrefix(_ n: Int) -> [Element] {
        precondition(n >= 0, "Array.takePrefix(_:) n must be >= 0")
        if n >= count {
            return self
        } else if n <= 0 {
            return []
        }
        return Array(self[0..<n])
    }

    /// Returns a new array containing the last `n` elements.
    /// - Parameter n: The maximum number of elements to return.
    /// - Returns: An array containing at most the last `n` elements.
    /// - Precondition: n must be >= 0
    public func takeSuffix(_ n: Int) -> [Element] {
        precondition(n >= 0, "Array.takeSuffix(_:) n must be >= 0")
        if n >= count {
            return self
        } else if n <= 0 {
            return []
        }
        return Array(self[(count - n)..<count])
    }

    /// Finds the index of an element in the array using binary search.
    /// - Complexity: O(log n) where n is the length of the array
    /// - Precondition: The array MUST be sorted in ascending order according to the comparison function
    /// - Parameters:
    ///   - element: The element to find.
    ///   - compare: A closure that returns a comparison result for two elements.
    /// - Returns: The index of the element, or nil if not found.
    public func binarySearch<T>(for element: T, compare: (T, Element) -> ComparisonResult) -> Int? {
        var lowerBound = 0
        var upperBound = count - 1

        while lowerBound <= upperBound {
            let midIndex = lowerBound + (upperBound - lowerBound) / 2
            let midElement = self[midIndex]

            switch compare(element, midElement) {
            case .orderedSame:
                return midIndex
            case .orderedAscending:
                upperBound = midIndex - 1
            case .orderedDescending:
                lowerBound = midIndex + 1
            }
        }

        return nil
    }

    /// Performs a binary search on a sorted array where Element conforms to Comparable.
    /// - Complexity: O(log n) where n is the length of the array
    /// - Precondition: The array MUST be sorted in ascending order
    /// - Parameter element: The element to find.
    /// - Returns: The index of the element, or nil if not found.
    public func binarySearch(for element: Element) -> Int? where Element: Comparable {
        return binarySearch(for: element) { (a, b) -> ComparisonResult in
            if a < b {
                return .orderedAscending
            } else if a > b {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }
    }

    /// Returns a new array by removing the element at the specified index.
    /// - Parameter index: The index of the element to remove.
    /// - Returns: A new array with the element at index removed.
    /// - Precondition: Index must be within bounds.
    public func removing(at index: Int) -> [Element] {
        precondition(indices.contains(index), "Index \(index) out of bounds [0..<\(count)]")
        var result = self
        result.remove(at: index)
        return result
    }

    /// Returns a new array by replacing the element at the specified index.
    /// - Parameters:
    ///   - index: The index of the element to replace.
    ///   - newElement: The new element to put at index.
    /// - Returns: A new array with the element at index replaced by newElement.
    /// - Precondition: Index must be within bounds.
    public func replacing(at index: Int, with newElement: Element) -> [Element] {
        precondition(indices.contains(index), "Index \(index) out of bounds [0..<\(count)]")
        var result = self
        result[index] = newElement
        return result
    }

    /// Returns a new array by inserting the element at the specified index.
    /// - Parameters:
    ///   - newElement: The new element to insert.
    ///   - index: The index at which to insert the element.
    /// - Returns: A new array with newElement inserted at index.
    /// - Precondition: Index must be within bounds [0...count].
    public func inserting(_ newElement: Element, at index: Int) -> [Element] {
        precondition(index >= 0 && index <= count, "Index \(index) out of bounds [0...\(count)]")
        var result = self
        result.insert(newElement, at: index)
        return result
    }

    /// Returns a new array with the first occurrence of `element` removed.
    /// Only applicable to arrays with elements that conform to Equatable.
    /// - Parameter element: The element to remove.
    /// - Returns: A new array with the first occurrence of `element` removed.
    public func removing(_ element: Element) -> [Element] where Element: Equatable {
        guard let index = firstIndex(of: element) else { return self }
        return removing(at: index)
    }

    /// Returns a new array with all occurrences of `element` removed.
    /// Only applicable to arrays with elements that conform to Equatable.
    /// - Parameter element: The element to remove.
    /// - Returns: A new array with all occurrences of `element` removed.
    public func removingAll(of element: Element) -> [Element] where Element: Equatable {
        return filter { $0 != element }
    }

    /// Creates a dictionary with the keys and values provided by the given closures.
    /// - Parameters:
    ///   - keyForValue: A closure that returns a key for each element.
    ///   - valueForKey: A closure that returns a value for each key.
    /// - Returns: A dictionary with keys and values provided by the closures.
    public func toDictionary<K: Hashable, V>(keyForValue: (Element) -> K, valueForKey: (Element) -> V)
        -> [K: V]
    {
        var result = [K: V]()
        for element in self {
            let key = keyForValue(element)
            let value = valueForKey(element)
            result[key] = value
        }
        return result
    }

    /// Creates a dictionary with the keys provided by the given closure and the elements as values.
    /// - Parameter keyForValue: A closure that returns a key for each element.
    /// - Returns: A dictionary with keys provided by the closure and elements as values.
    public func toDictionary<K: Hashable>(keyForValue: (Element) -> K) -> [K: Element] {
        return toDictionary(keyForValue: keyForValue, valueForKey: { $0 })
    }

    /// Returns the indices of all occurrences of `element` in the array.
    /// Only applicable to arrays with elements that conform to Equatable.
    /// - Parameter element: The element to find.
    /// - Returns: An array of indices for the element.
    public func indices(of element: Element) -> [Int] where Element: Equatable {
        var indices = [Int]()
        for (index, e) in enumerated() where e == element {
            indices.append(index)
        }
        return indices
    }
}
