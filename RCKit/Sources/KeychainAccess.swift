//
//  KeychainAccess.swift
//
//
//  Created by RoCry on 2024/5/1.
//

import Foundation
import Security

/// A utility class for securely storing and retrieving sensitive data using the keychain
public class KeychainAccess {

  /// Service identifier for the keychain items
  public let service: String

  /// Access group for shared keychain items (optional)
  public let accessGroup: String?

  private let jsonEncoder: JSONEncoder
  private let jsonDecoder: JSONDecoder

  /// Initialize a KeychainAccess instance
  /// - Parameters:
  ///   - service: Service identifier for the keychain items
  ///   - accessGroup: Access group for shared keychain items (optional)
  public init(service: String, accessGroup: String? = nil) {
    self.service = service
    self.accessGroup = accessGroup
    self.jsonEncoder = JSONCoding.makeEncoder()
    self.jsonDecoder = JSONCoding.makeDecoder()
  }

  // MARK: - String Operations

  /// Store a string value in the keychain
  /// - Parameters:
  ///   - value: The string value to store
  ///   - account: The account identifier (key)
  /// - Returns: A result indicating success or the error that occurred
  @discardableResult
  public func set(_ value: String, for account: String) -> Result<Void, KeychainError> {
    guard let data = value.data(using: .utf8) else {
      return .failure(.dataEncoding)
    }

    return set(data, for: account)
  }

  /// Retrieve a string value from the keychain
  /// - Parameter account: The account identifier (key)
  /// - Returns: A result containing the retrieved string or the error that occurred
  public func getString(for account: String) -> Result<String, KeychainError> {
    return getData(for: account).flatMap { data in
      guard let string = String(data: data, encoding: .utf8) else {
        return .failure(.dataDecoding)
      }
      return .success(string)
    }
  }

  // MARK: - Data Operations

  /// Store data in the keychain
  /// - Parameters:
  ///   - data: The data to store
  ///   - account: The account identifier (key)
  /// - Returns: A result indicating success or the error that occurred
  @discardableResult
  public func set(_ data: Data, for account: String) -> Result<Void, KeychainError> {
    // First try to update an existing item
    var query = baseQuery(for: account)

    let attributesToUpdate: [String: Any] = [
      kSecValueData as String: data
    ]

    let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

    if status == errSecSuccess {
      return .success(())
    }

    // Item not found, need to add it
    if status == errSecItemNotFound {
      // Add the data to the existing query for adding
      query[kSecValueData as String] = data

      let addStatus = SecItemAdd(query as CFDictionary, nil)
      if addStatus == errSecSuccess {
        return .success(())
      } else {
        return .failure(.unhandledError(status: addStatus))
      }
    }

    return .failure(.unhandledError(status: status))
  }

  /// Retrieve data from the keychain
  /// - Parameter account: The account identifier (key)
  /// - Returns: A result containing the retrieved data or the error that occurred
  public func getData(for account: String) -> Result<Data, KeychainError> {
    var query = baseQuery(for: account)
    query[kSecReturnData as String] = kCFBooleanTrue
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess else {
      return .failure(
        status == errSecItemNotFound ? .itemNotFound : .unhandledError(status: status))
    }

    guard let data = result as? Data else {
      return .failure(.unexpectedItemData)
    }

    return .success(data)
  }

  // MARK: - Boolean Operations

  /// Store a boolean value in the keychain
  /// - Parameters:
  ///   - value: The boolean value to store
  ///   - account: The account identifier (key)
  /// - Returns: A result indicating success or the error that occurred
  @discardableResult
  public func set(_ value: Bool, for account: String) -> Result<Void, KeychainError> {
    let data = Data([value ? 1 : 0])
    return set(data, for: account)
  }

  /// Retrieve a boolean value from the keychain
  /// - Parameter account: The account identifier (key)
  /// - Returns: A result containing the retrieved boolean or the error that occurred
  public func getBool(for account: String) -> Result<Bool, KeychainError> {
    return getData(for: account).flatMap { data in
      guard let firstByte = data.first else {
        return .failure(.dataDecoding)
      }
      return .success(firstByte != 0)
    }
  }

  // MARK: - Codable Operations

  /// Store a Codable object in the keychain
  /// - Parameters:
  ///   - value: The Codable object to store
  ///   - account: The account identifier (key)
  /// - Returns: A result indicating success or the error that occurred
  @discardableResult
  public func set<T: Encodable>(_ value: T, for account: String) -> Result<Void, KeychainError> {
    do {
      let data = try jsonEncoder.encode(value)
      return set(data, for: account)
    } catch {
      return .failure(.jsonEncoding(error))
    }
  }

  /// Retrieve a Codable object from the keychain
  /// - Parameters:
  ///   - account: The account identifier (key)
  ///   - type: The type of object to retrieve
  /// - Returns: A result containing the retrieved object or the error that occurred
  public func getCodable<T: Decodable>(for account: String, as type: T.Type) -> Result<
    T, KeychainError
  > {
    return getData(for: account).flatMap { data in
      do {
        let value = try jsonDecoder.decode(type, from: data)
        return .success(value)
      } catch {
        return .failure(.jsonDecoding(error))
      }
    }
  }

  // MARK: - Deletion

  /// Delete an item from the keychain
  /// - Parameter account: The account identifier (key)
  /// - Returns: A result indicating success or the error that occurred
  @discardableResult
  public func delete(for account: String) -> Result<Void, KeychainError> {
    let query = baseQuery(for: account)

    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      return .failure(.unhandledError(status: status))
    }

    return .success(())
  }

  /// Check if an item exists in the keychain
  /// - Parameter account: The account identifier (key)
  /// - Returns: A boolean indicating whether the item exists
  public func exists(for account: String) -> Bool {
    let query = baseQuery(for: account)
    let status = SecItemCopyMatching(query as CFDictionary, nil)
    return status == errSecSuccess
  }

  // MARK: - Private Helpers

  /// Create a base query dictionary for keychain operations
  /// - Parameter account: The account identifier (key)
  /// - Returns: A dictionary with the base query parameters
  private func baseQuery(for account: String) -> [String: Any] {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]

    if let accessGroup = accessGroup {
      query[kSecAttrAccessGroup as String] = accessGroup
    }

    return query
  }
}

/// Errors that can occur during keychain operations
public enum KeychainError: Error, LocalizedError, Equatable {
  /// The data couldn't be encoded to UTF-8
  case dataEncoding

  /// The data couldn't be decoded from UTF-8
  case dataDecoding

  /// The object couldn't be encoded to JSON
  case jsonEncoding(Error)

  /// The object couldn't be decoded from JSON
  case jsonDecoding(Error)

  /// The item didn't exist in the keychain
  case itemNotFound

  /// The data retrieved from the keychain was unexpected
  case unexpectedItemData

  /// An unhandled security framework error occurred
  case unhandledError(status: OSStatus)

  /// A description of the error
  public var errorDescription: String? {
    switch self {
    case .dataEncoding:
      return "Failed to encode data to UTF-8"
    case .dataDecoding:
      return "Failed to decode data from UTF-8"
    case .jsonEncoding(let error):
      return "Failed to encode object to JSON: \(error.localizedDescription)"
    case .jsonDecoding(let error):
      return "Failed to decode object from JSON: \(error.localizedDescription)"
    case .itemNotFound:
      return "Item not found in keychain"
    case .unexpectedItemData:
      return "Unexpected data format in keychain"
    case .unhandledError(let status):
      return "Unhandled keychain error (status: \(status))"
    }
  }

  /// Compare two KeychainError instances for equality
  public static func == (lhs: KeychainError, rhs: KeychainError) -> Bool {
    switch (lhs, rhs) {
    case (.dataEncoding, .dataEncoding),
      (.dataDecoding, .dataDecoding),
      (.itemNotFound, .itemNotFound),
      (.unexpectedItemData, .unexpectedItemData):
      return true
    case (.jsonEncoding, .jsonEncoding),
      (.jsonDecoding, .jsonDecoding):
      // Errors with associated values are inherently not comparable without type info
      // Two encoding/decoding errors are considered equal only if they're the same case
      return false
    case (.unhandledError(let lhsStatus), .unhandledError(let rhsStatus)):
      return lhsStatus == rhsStatus
    default:
      return false
    }
  }
}
