import Foundation
import SQLiteData
import XCTest
@testable import RCKitDemo

final class SQLiteDataDemoDatabaseTests: XCTestCase {
    func testMigrationAndInsert() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let databaseURL = directory.appendingPathComponent("demo.sqlite")
        let database = try SQLiteDataDemoDatabase.makeDatabase(at: databaseURL)

        let utcString = UTCDateFormatter.iso8601String(from: Date(timeIntervalSince1970: 0))
        let insertedID = try database.write { db in
            try DemoNote
                .insert {
                    DemoNote.Draft(title: "Test", createdAtUTC: utcString)
                }
                .returning(\.id)
                .fetchOne(db)
        }

        XCTAssertNotNil(insertedID)

        let count = try database.read { db in
            try DemoNote.count().fetchOne(db) ?? 0
        }
        XCTAssertEqual(count, 1)
    }
}
