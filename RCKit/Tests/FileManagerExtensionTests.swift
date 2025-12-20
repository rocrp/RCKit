//
//  FileManagerExtensionTests.swift
//
//
//  Created by RoCry on 2024/5/1.
//

import XCTest

@testable import RCKit

final class FileManagerExtensionTests: XCTestCase {

  var testDirectory: URL!
  let fileManager = FileManager.default

  override func setUp() {
    super.setUp()

    // Create a temporary directory for testing
    testDirectory = fileManager.temporaryDirectory.appendingPathComponent(
      "RCKitTest_\(UUID().uuidString)")
    try? fileManager.createDirectory(
      at: testDirectory, withIntermediateDirectories: true, attributes: nil)
  }

  override func tearDown() {
    // Clean up test directory after tests
    try? fileManager.removeItem(at: testDirectory)
    super.tearDown()
  }

  // MARK: - Directory Path Tests

  func testDirectoryURLs() {
    XCTAssertNotNil(FileManager.documentsDirectoryURL)
    XCTAssertNotNil(FileManager.libraryDirectoryURL)
    XCTAssertNotNil(FileManager.cachesDirectoryURL)
    XCTAssertNotNil(FileManager.temporaryDirectoryURL)

    XCTAssertTrue(FileManager.documentsDirectoryURL.path.contains("Documents"))
    XCTAssertTrue(FileManager.libraryDirectoryURL.path.contains("Library"))
    XCTAssertTrue(FileManager.cachesDirectoryURL.path.contains("Caches"))
  }

  // MARK: - File Operation Tests

  func testSaveAndReadData() throws {
    // Test data
    let testData = "Hello, world!".data(using: .utf8)!
    let filename = "test.txt"

    // Save data
    let savedURL = try fileManager.saveData(testData, to: testDirectory, as: filename)
    XCTAssertEqual(savedURL.lastPathComponent, filename)
    XCTAssertTrue(fileManager.fileExists(atPath: savedURL.path))

    // Read data
    let readData = try fileManager.readData(from: testDirectory, filename: filename)
    XCTAssertEqual(readData, testData)
    XCTAssertEqual(String(data: readData, encoding: .utf8), "Hello, world!")
  }

  func testFileExists() throws {
    let filename = "exists.txt"
    let testData = "Test data".data(using: .utf8)!

    // Initially file doesn't exist
    XCTAssertFalse(fileManager.fileExists(in: testDirectory, withName: filename))

    // Create file
    try fileManager.saveData(testData, to: testDirectory, as: filename)

    // Now file should exist
    XCTAssertTrue(fileManager.fileExists(in: testDirectory, withName: filename))
  }

  func testRemoveFile() throws {
    let filename = "to_remove.txt"
    let testData = "Test data".data(using: .utf8)!

    // Create file
    try fileManager.saveData(testData, to: testDirectory, as: filename)
    XCTAssertTrue(fileManager.fileExists(in: testDirectory, withName: filename))

    // Remove file
    try fileManager.removeFile(from: testDirectory, filename: filename)
    XCTAssertFalse(fileManager.fileExists(in: testDirectory, withName: filename))

    // Removing non-existent file should throw
    XCTAssertThrowsError(
      try fileManager.removeFile(from: testDirectory, filename: "nonexistent.txt"))
  }

  func testCreateDirectoryIfNeeded() throws {
    let subdir = testDirectory.appendingPathComponent("subdir")

    // Create directory
    let created = try fileManager.createDirectoryIfNeeded(at: subdir)
    XCTAssertTrue(created)

    // Directory already exists, should return false
    let createdAgain = try fileManager.createDirectoryIfNeeded(at: subdir)
    XCTAssertFalse(createdAgain)

    // Test with a file path
    let filePath = testDirectory.appendingPathComponent("file.txt")
    let fileData = "Test".data(using: .utf8)!
    try fileData.write(to: filePath)

    // Should throw when a file exists at the path
    XCTAssertThrowsError(try fileManager.createDirectoryIfNeeded(at: filePath))

    var isDirectory: ObjCBool = false
    XCTAssertTrue(fileManager.fileExists(atPath: filePath.path, isDirectory: &isDirectory))
    XCTAssertFalse(isDirectory.boolValue)
  }

  // MARK: - JSON Operation Tests

  func testSaveAndReadJSON() throws {
    struct TestObject: Codable, Equatable {
      let id: Int
      let name: String
    }

    let testObject = TestObject(id: 1, name: "Test")
    let filename = "test.json"

    // Save JSON
    let savedURL = try fileManager.saveJSON(testObject, to: testDirectory, as: filename)
    XCTAssertEqual(savedURL.lastPathComponent, filename)

    // Read JSON
    let readObject = try fileManager.readJSON(
      as: TestObject.self, from: testDirectory, filename: filename)
    XCTAssertEqual(readObject, testObject)
  }

  // MARK: - File Attribute Tests

  func testGetFileSize() throws {
    let filename = "size_test.txt"
    let testData = String(repeating: "a", count: 1000).data(using: .utf8)!

    // Save data
    try fileManager.saveData(testData, to: testDirectory, as: filename)

    // Get file size
    let size = try fileManager.getFileSize(in: testDirectory, filename: filename)
    XCTAssertEqual(size, UInt64(testData.count))
  }

  func testGetFileModificationDate() throws {
    let filename = "date_test.txt"
    let testData = "Test data".data(using: .utf8)!

    let beforeDate = Date()

    // Small delay to ensure date difference
    usleep(10_000)  // 10 ms

    // Save data
    try fileManager.saveData(testData, to: testDirectory, as: filename)

    usleep(10_000)  // 10 ms

    let afterDate = Date()

    // Get modification date
    let modDate = try fileManager.getFileModificationDate(in: testDirectory, filename: filename)

    // The modification date should be between before and after dates
    XCTAssertGreaterThan(modDate, beforeDate)
    XCTAssertLessThan(modDate, afterDate)
  }

  // MARK: - Directory Operation Tests

  func testListContents() throws {
    // Create some files
    try fileManager.saveData("File 1".data(using: .utf8)!, to: testDirectory, as: "file1.txt")
    try fileManager.saveData("File 2".data(using: .utf8)!, to: testDirectory, as: "file2.txt")

    // Create a subdirectory with a file
    let subdir = testDirectory.appendingPathComponent("subdir")
    try fileManager.createDirectory(at: subdir, withIntermediateDirectories: true)
    try fileManager.saveData("Subfile".data(using: .utf8)!, to: subdir, as: "subfile.txt")

    // List without subdirectories
    let contents = try fileManager.listContents(of: testDirectory)
    XCTAssertEqual(contents.count, 3)  // file1.txt, file2.txt, subdir

    // Check file names
    let fileNames = contents.map { $0.lastPathComponent }.sorted()
    XCTAssertEqual(fileNames, ["file1.txt", "file2.txt", "subdir"])

    // List with subdirectories
    let allContents = try fileManager.listContents(of: testDirectory, includeSubdirectories: true)
    XCTAssertEqual(allContents.count, 4)  // file1.txt, file2.txt, subdir, subdir/subfile.txt
    let allNames = allContents.map { $0.lastPathComponent }
    XCTAssertTrue(allNames.contains("subfile.txt"))
  }

  func testClearDirectory() throws {
    // Create some files
    try fileManager.saveData("File 1".data(using: .utf8)!, to: testDirectory, as: "file1.txt")
    try fileManager.saveData("File 2".data(using: .utf8)!, to: testDirectory, as: "file2.txt")

    // Create a subdirectory with a file
    let subdir = testDirectory.appendingPathComponent("subdir")
    try fileManager.createDirectory(at: subdir, withIntermediateDirectories: true)
    try fileManager.saveData("Subfile".data(using: .utf8)!, to: subdir, as: "subfile.txt")

    // Verify files exist
    XCTAssertEqual(try fileManager.contentsOfDirectory(atPath: testDirectory.path).count, 3)

    // Clear directory
    try fileManager.clearDirectory(testDirectory)

    // Verify directory is empty
    XCTAssertEqual(try fileManager.contentsOfDirectory(atPath: testDirectory.path).count, 0)
  }

  // MARK: - Helper Methods Tests

  func testUniqueFilename() {
    let basename = "test"
    let ext = "txt"

    let filename1 = FileManager.uniqueFilename(withBasename: basename, extension: ext)

    // Add a small delay to ensure different timestamps
    usleep(1_000_000)  // 1 second delay

    // Unique filename should include basename
    XCTAssertTrue(filename1.hasPrefix(basename))

    // Unique filename should include extension
    XCTAssertTrue(filename1.hasSuffix(".\(ext)"))

    // Unique filename without extension
    let filename2 = FileManager.uniqueFilename(withBasename: basename)
    XCTAssertTrue(filename2.hasPrefix(basename))
    XCTAssertFalse(filename2.contains("."))

    // Two consecutive calls should give different filenames
    let filename3 = FileManager.uniqueFilename(withBasename: basename, extension: ext)
    XCTAssertNotEqual(filename1, filename3)
  }
}
