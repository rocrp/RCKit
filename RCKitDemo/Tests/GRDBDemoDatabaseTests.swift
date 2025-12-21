import Foundation
import GRDB
import XCTest
@testable import RCKitDemo

final class GRDBDemoDatabaseTests: XCTestCase {
    func testMigrationAndInsert() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let databaseURL = directory.appendingPathComponent("demo.sqlite")
        let database = try DemoDatabase.makeForTesting(at: databaseURL)

        let utcString = UTCDateFormatter.iso8601String(from: Date(timeIntervalSince1970: 0))
        var note = DemoNote(id: nil, title: "Test", createdAtUTC: utcString)
        try database.saveNote(&note)

        XCTAssertNotNil(note.id)

        let count = try database.reader.read { db in
            try DemoNote.fetchCount(db)
        }
        XCTAssertEqual(count, 1)
    }
}
