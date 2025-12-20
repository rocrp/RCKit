//
//  FileManager+Extension.swift
//
//
//  Created by RoCry on 2024/5/1.
//

import Foundation

public enum FileManagerExtensionError: Error, LocalizedError {
  case fileNotFound(URL)
  case notADirectory(URL)
  case invalidFileAttributes(URL)

  public var errorDescription: String? {
    switch self {
    case .fileNotFound(let url):
      return "File not found: \(url.path)"
    case .notADirectory(let url):
      return "Expected directory but found file: \(url.path)"
    case .invalidFileAttributes(let url):
      return "Invalid file attributes for: \(url.path)"
    }
  }
}

extension FileManager {

  // MARK: - Directory Paths

  /// Get the documents directory URL
  public static var documentsDirectoryURL: URL {
    guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    else {
      preconditionFailure("Documents directory unavailable")
    }
    return url
  }

  /// Get the library directory URL
  public static var libraryDirectoryURL: URL {
    guard let url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
    else {
      preconditionFailure("Library directory unavailable")
    }
    return url
  }

  /// Get the caches directory URL
  public static var cachesDirectoryURL: URL {
    guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    else {
      preconditionFailure("Caches directory unavailable")
    }
    return url
  }

  /// Get the temporary directory URL
  public static var temporaryDirectoryURL: URL {
    let path = NSTemporaryDirectory()
    precondition(!path.isEmpty, "Temporary directory path unavailable")
    return URL(fileURLWithPath: path)
  }

  // MARK: - File Operations

  /// Save data to a file
  /// - Parameters:
  ///   - data: Data to save
  ///   - directory: Directory to save to
  ///   - filename: Filename to save as
  /// - Returns: URL where the file was saved
  /// - Throws: Error if saving fails
  @discardableResult
  public func saveData(_ data: Data, to directory: URL, as filename: String) throws -> URL {
    let fileURL = directory.appendingPathComponent(filename)
    try data.write(to: fileURL, options: .atomic)
    return fileURL
  }

  /// Read data from a file
  /// - Parameters:
  ///   - directory: Directory to read from
  ///   - filename: Filename to read
  /// - Returns: Data from the file
  /// - Throws: Error if reading fails
  public func readData(from directory: URL, filename: String) throws -> Data {
    let fileURL = directory.appendingPathComponent(filename)
    return try Data(contentsOf: fileURL)
  }

  /// Check if a file exists
  /// - Parameters:
  ///   - directory: Directory to check in
  ///   - filename: Filename to check
  /// - Returns: Whether the file exists
  public func fileExists(in directory: URL, withName filename: String) -> Bool {
    let fileURL = directory.appendingPathComponent(filename)
    return fileExists(atPath: fileURL.path)
  }

  /// Remove a file
  /// - Parameters:
  ///   - directory: Directory containing the file
  ///   - filename: Filename to remove
  /// - Throws: Error if removal fails
  public func removeFile(from directory: URL, filename: String) throws {
    let fileURL = directory.appendingPathComponent(filename)
    guard fileExists(atPath: fileURL.path) else {
      throw FileManagerExtensionError.fileNotFound(fileURL)
    }
    try removeItem(at: fileURL)
  }

  /// Create a directory if it doesn't exist
  /// - Parameters:
  ///   - url: URL for the directory
  ///   - withIntermediateDirectories: Whether to create intermediate directories
  /// - Returns: Whether the directory was created (true) or already existed (false)
  /// - Throws: Error if creation fails
  @discardableResult
  public func createDirectoryIfNeeded(at url: URL, withIntermediateDirectories: Bool = true) throws
    -> Bool
  {
    var isDirectory: ObjCBool = false
    let exists = fileExists(atPath: url.path, isDirectory: &isDirectory)

    if exists && isDirectory.boolValue {
      return false
    } else if exists && !isDirectory.boolValue {
      throw FileManagerExtensionError.notADirectory(url)
    } else {
      try createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
      return true
    }
  }

  // MARK: - JSON Operations

  /// Save a JSON-encodable object to a file
  /// - Parameters:
  ///   - object: Object to save
  ///   - directory: Directory to save to
  ///   - filename: Filename to save as
  ///   - encoder: JSONEncoder to use (optional)
  /// - Returns: URL where the file was saved
  /// - Throws: Error if encoding or saving fails
  @discardableResult
  public func saveJSON<T: Encodable>(
    _ object: T, to directory: URL, as filename: String,
    encoder: JSONEncoder = JSONCoding.makeEncoder()
  ) throws -> URL {
    let data = try encoder.encode(object)
    return try saveData(data, to: directory, as: filename)
  }

  /// Read a JSON-decodable object from a file
  /// - Parameters:
  ///   - type: Type to decode as
  ///   - directory: Directory to read from
  ///   - filename: Filename to read
  ///   - decoder: JSONDecoder to use (optional)
  /// - Returns: Decoded object
  /// - Throws: Error if reading or decoding fails
  public func readJSON<T: Decodable>(
    as type: T.Type, from directory: URL, filename: String,
    decoder: JSONDecoder = JSONCoding.makeDecoder()
  ) throws -> T {
    let data = try readData(from: directory, filename: filename)
    return try decoder.decode(type, from: data)
  }

  // MARK: - File Attributes

  /// Get the size of a file
  /// - Parameters:
  ///   - directory: Directory containing the file
  ///   - filename: Filename to check
  /// - Returns: Size of the file in bytes
  /// - Throws: Error if getting attributes fails
  public func getFileSize(in directory: URL, filename: String) throws -> UInt64 {
    let fileURL = directory.appendingPathComponent(filename)
    let attributes = try attributesOfItem(atPath: fileURL.path)
    guard let size = attributes[.size] as? UInt64 else {
      throw FileManagerExtensionError.invalidFileAttributes(fileURL)
    }
    return size
  }

  /// Get the modification date of a file
  /// - Parameters:
  ///   - directory: Directory containing the file
  ///   - filename: Filename to check
  /// - Returns: Modification date of the file
  /// - Throws: Error if getting attributes fails
  public func getFileModificationDate(in directory: URL, filename: String) throws -> Date {
    let fileURL = directory.appendingPathComponent(filename)
    let attributes = try attributesOfItem(atPath: fileURL.path)
    guard let date = attributes[.modificationDate] as? Date else {
      throw FileManagerExtensionError.invalidFileAttributes(fileURL)
    }
    return date
  }

  // MARK: - Directory Operations

  /// List contents of a directory
  /// - Parameters:
  ///   - directory: Directory to list
  ///   - includeSubdirectories: Whether to include subdirectories
  /// - Returns: Array of URLs for items in the directory
  /// - Throws: Error if listing fails
  public func listContents(of directory: URL, includeSubdirectories: Bool = false) throws -> [URL] {
    let keys: [URLResourceKey] = [.isDirectoryKey]
    var isDirectory: ObjCBool = false
    let exists = fileExists(atPath: directory.path, isDirectory: &isDirectory)
    guard exists else {
      throw FileManagerExtensionError.fileNotFound(directory)
    }
    guard isDirectory.boolValue else {
      throw FileManagerExtensionError.notADirectory(directory)
    }

    if includeSubdirectories {
      var results: [URL] = []
      var firstError: Error?
      let enumerator = self.enumerator(
        at: directory,
        includingPropertiesForKeys: keys,
        options: [],
        errorHandler: { _, error in
          firstError = error
          return false
        }
      )

      guard let enumerator else {
        preconditionFailure("Failed to enumerate directory: \(directory.path)")
      }

      for case let url as URL in enumerator {
        results.append(url)
      }

      if let firstError {
        throw firstError
      }

      return results
    }

    return try contentsOfDirectory(
      at: directory, includingPropertiesForKeys: keys, options: .skipsSubdirectoryDescendants)
  }

  /// Clear all contents of a directory
  /// - Parameter directory: Directory to clear
  /// - Throws: Error if clearing fails
  public func clearDirectory(_ directory: URL) throws {
    let contents = try contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
    for fileURL in contents {
      try removeItem(at: fileURL)
    }
  }

  // MARK: - File URL Extensions

  /// Create a unique filename with timestamp
  /// - Parameters:
  ///   - basename: Base name for the file
  ///   - extension: File extension
  /// - Returns: Unique filename
  public static func uniqueFilename(
    withBasename basename: String, extension fileExtension: String? = nil
  ) -> String {
    let timestamp = Int(Date().timeIntervalSince1970 * 1_000)
    if let fileExtension = fileExtension {
      return "\(basename)_\(timestamp).\(fileExtension)"
    } else {
      return "\(basename)_\(timestamp)"
    }
  }
}
