//
//  Random.swift
//
//
//  Created by RoCry on 2024/1/24.
//

import Foundation
import Security

/// Protocol for types that can generate random instances
public protocol Randomable {
    /// Generate a random instance with specified size parameter
    static func random(size: Int) -> Self

    /// Generate a random instance with default size
    static func random() -> Self
}

extension Randomable {
    /// Default implementation with size 10
    public static func random() -> Self {
        return self.random(size: 10)
    }
}

// MARK: - Basic Types

extension Bool: Randomable {
    public static func random(size: Int) -> Self {
        precondition(size >= 0, "Bool.random(size:) size must be >= 0")
        return Bool.random()
    }
}

extension Int: Randomable {
    public static func random(size: Int) -> Self {
        precondition(size > 0, "Int.random(size:) size must be > 0")
        return Int.random(in: 0 ..< size)
    }
}

extension Double: Randomable {
    public static func random(size: Int) -> Self {
        precondition(size > 0, "Double.random(size:) size must be > 0")
        return Double.random(in: 0 ..< Double(size))
    }
}

extension Float: Randomable {
    public static func random(size: Int) -> Self {
        precondition(size > 0, "Float.random(size:) size must be > 0")
        return Float.random(in: 0 ..< Float(size))
    }
}

// MARK: - Character & String

extension Character: Randomable {
    public static func random(size: Int) -> Self {
        precondition(size >= 0, "Character.random(size:) size must be >= 0")
        return random(from: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    }

    /// Generate a random character from a specific set of characters
    public static func random(from characters: String) -> Self {
        guard let char = characters.randomElement() else {
            preconditionFailure("Character set must not be empty")
        }
        return char
    }

    /// Generate a random alphanumeric character
    public static var randomAlphanumeric: Self {
        return random(from: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    }

    /// Generate a random lowercase letter
    public static var randomLowercase: Self {
        return random(from: "abcdefghijklmnopqrstuvwxyz")
    }

    /// Generate a random uppercase letter
    public static var randomUppercase: Self {
        return random(from: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    }

    /// Generate a random digit
    public static var randomDigit: Self {
        return random(from: "0123456789")
    }
}

extension String: Randomable {
    public static func random(size: Int) -> Self {
        precondition(size >= 0, "String.random(size:) size must be >= 0")
        return String((0 ..< size).map { _ in Character.random() })
    }

    /// Generate a random string from a specific set of characters
    public static func random(size: Int, from characterSet: String) -> Self {
        precondition(size >= 0, "String.random(size:from:) size must be >= 0")
        return String((0 ..< size).map { _ in Character.random(from: characterSet) })
    }

    /// Generate a random alphanumeric string
    public static func randomAlphanumeric(size: Int) -> Self {
        precondition(size >= 0, "String.randomAlphanumeric(size:) size must be >= 0")
        return random(
            size: size,
            from: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        )
    }

    /// Generate a random hexadecimal string
    public static func randomHex(size: Int) -> Self {
        precondition(size >= 0, "String.randomHex(size:) size must be >= 0")
        return random(size: size, from: "0123456789abcdef")
    }

    /// Generate a cryptographically secure random string encoded as hex
    public static func randomSecure(size: Int) -> Self {
        precondition(size >= 0, "String.randomSecure(size:) size must be >= 0")
        return Data.random(size: size).map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Collections

extension Array: Randomable where Element: Randomable {
    public static func random(size: Int) -> Self {
        precondition(size >= 0, "Array.random(size:) size must be >= 0")
        return (0 ..< size).map { _ in Element.random() }
    }

    /// Select a specified number of random elements from the array
    public func randomElements(count: Int) -> [Element] {
        precondition(count >= 0, "Array.randomElements(count:) count must be >= 0")
        precondition(
            count <= self.count,
            "Array.randomElements(count:) count \(count) exceeds array count \(self.count)"
        )
        guard count > 0 else { return [] }

        var array = self
        var result: [Element] = []

        for _ in 0 ..< count {
            let randomIndex = Int.random(in: 0 ..< array.count)
            result.append(array[randomIndex])
            array.remove(at: randomIndex)
        }

        return result
    }

}

// MARK: - UUID

extension UUID: Randomable {
    public static func random(size: Int) -> UUID {
        precondition(size >= 0, "UUID.random(size:) size must be >= 0")
        return UUID()
    }
}

// MARK: - Data

extension Data: Randomable {
    public static func random(size: Int) -> Data {
        precondition(size >= 0, "Data.random(size:) size must be >= 0")
        var data = Data(count: size)
        data.withUnsafeMutableBytes { pointer in
            guard let baseAddress = pointer.baseAddress else {
                preconditionFailure("Failed to get base address for random data generation")
            }
            let status = SecRandomCopyBytes(kSecRandomDefault, size, baseAddress)
            precondition(status == errSecSuccess, "SecRandomCopyBytes failed with status \(status)")
        }
        return data
    }

    /// Generate cryptographically secure random data
    public static func randomSecure(size: Int) -> Data {
        return random(size: size)
    }
}
