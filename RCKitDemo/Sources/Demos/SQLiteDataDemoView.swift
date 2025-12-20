import Foundation
import SQLiteData
import SwiftUI

@Table("demo_notes")
struct DemoNote: Identifiable {
  let id: Int64
  var title: String = ""
  var createdAtUTC: String = ""
}

struct SQLiteDataDemoView: View {
  @FetchAll(DemoNote.order(by: \.createdAtUTC)) private var notes: [DemoNote]
  @FetchOne(DemoNote.count()) private var notesCount = 0
  @Dependency(\.defaultDatabase) private var database

  @State private var newTitle: String = ""
  @State private var lastInsertedID: String = ""
  @State private var lastInsertedUTC: String = ""

  var body: some View {
    Section("Database") {
      ValueRow(title: "Path", value: SQLiteDataDemoDatabase.databasePath ?? "<not ready>")
      ValueRow(title: "Total Notes", value: String(notesCount))
    }

    Section("Insert") {
      TextField("Note title", text: $newTitle)
        .textInputAutocapitalization(.sentences)
      Button("Insert Note") {
        insertNote()
      }
      .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      if !lastInsertedID.isEmpty {
        ValueRow(title: "Last ID", value: lastInsertedID)
      }
      if !lastInsertedUTC.isEmpty {
        ValueRow(title: "Last UTC", value: lastInsertedUTC)
      }
    }

    Section("Notes") {
      if notes.isEmpty {
        Text("No notes yet")
          .foregroundStyle(.secondary)
      }
      ForEach(notes) { note in
        VStack(alignment: .leading, spacing: 4) {
          Text(note.title)
            .font(.body)
          Text(note.createdAtUTC)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
      }
      Button("Delete All Notes", role: .destructive) {
        deleteAllNotes()
      }
      .disabled(notes.isEmpty)
    }
  }

  private func insertNote() {
    let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    let utcString = UTCDateFormatter.iso8601String(from: Date())

    do {
      let insertedID = try database.write { db in
        try DemoNote
          .insert {
            DemoNote.Draft(title: trimmed, createdAtUTC: utcString)
          }
          .returning(\.id)
          .fetchOne(db)
      }

      guard let insertedID else {
        preconditionFailure("SQLiteData insert returned nil ID")
      }

      lastInsertedID = String(insertedID)
      lastInsertedUTC = utcString
      newTitle = ""
    } catch {
      preconditionFailure("SQLiteData insert failed: \(error)")
    }
  }

  private func deleteAllNotes() {
    do {
      try database.write { db in
        try #sql("DELETE FROM \(DemoNote.self)").execute(db)
      }
      lastInsertedID = ""
      lastInsertedUTC = ""
    } catch {
      preconditionFailure("SQLiteData delete failed: \(error)")
    }
  }
}

enum SQLiteDataDemoDatabase {
  private static let fileName = "rckit-demo.sqlite"
  private static let folderName = "RCKitDemo"

  static var databasePath: String? {
    do {
      return try databaseURL().path
    } catch {
      return nil
    }
  }

  static func makeDatabase(at url: URL? = nil) throws -> DatabaseQueue {
    let databaseURL = try url ?? databaseURL()
    let database = try DatabaseQueue(path: databaseURL.path)
    try migrator.migrate(database)
    return database
  }

  private static func databaseURL() throws -> URL {
    let baseURL = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )

    let folderURL = baseURL.appendingPathComponent(folderName, isDirectory: true)
    try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

    return folderURL.appendingPathComponent(fileName)
  }

  private static var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()
    migrator.registerMigration("create_demo_notes") { db in
      try #sql(
        """
        CREATE TABLE "demo_notes" (
          "id" INTEGER PRIMARY KEY AUTOINCREMENT,
          "title" TEXT NOT NULL,
          "createdAtUTC" TEXT NOT NULL
        ) STRICT
        """
      )
      .execute(db)
    }
    return migrator
  }
}
