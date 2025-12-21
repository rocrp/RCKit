import Foundation
import GRDB
import SwiftUI

// MARK: - Model

struct DemoNote: Equatable {
    var id: Int64?
    var title: String
    var createdAtUTC: String
}

extension DemoNote: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "demo_notes"

    enum Columns {
        static let title = Column(CodingKeys.title)
        static let createdAtUTC = Column(CodingKeys.createdAtUTC)
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Database

struct DemoDatabase {
    private let dbWriter: any DatabaseWriter

    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        #if DEBUG
            migrator.eraseDatabaseOnSchemaChange = true
        #endif
        migrator.registerMigration("create_demo_notes") { db in
            try db.create(table: "demo_notes") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("createdAtUTC", .text).notNull()
            }
        }
        return migrator
    }

    func saveNote(_ note: inout DemoNote) throws {
        try dbWriter.write { db in
            try note.save(db)
        }
    }

    func deleteAllNotes() throws {
        try dbWriter.write { db in
            _ = try DemoNote.deleteAll(db)
        }
    }

    var reader: any DatabaseReader { dbWriter }
}

// MARK: - Shared Instance

extension DemoDatabase {
    static let shared = makeShared()

    private static func makeShared() -> DemoDatabase {
        do {
            let url = try databaseURL()
            let dbQueue = try DatabaseQueue(path: url.path)
            return try DemoDatabase(dbQueue)
        } catch {
            preconditionFailure("DemoDatabase setup failed: \(error)")
        }
    }

    static var databasePath: String? {
        try? databaseURL().path
    }

    private static func databaseURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = base.appendingPathComponent("RCKitDemo", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("rckit-demo.sqlite")
    }

    static func makeForTesting(at url: URL) throws -> DemoDatabase {
        let dbQueue = try DatabaseQueue(path: url.path)
        return try DemoDatabase(dbQueue)
    }
}

// MARK: - View

struct GRDBDemoView: View {
    @State private var notes: [DemoNote] = []
    @State private var notesCount = 0
    @State private var newTitle = ""
    @State private var lastInsertedID = ""
    @State private var lastInsertedUTC = ""
    @State private var observationCancellable: AnyDatabaseCancellable?

    private let database = DemoDatabase.shared

    var body: some View {
        Section("Database") {
            ValueRow(title: "Path", value: DemoDatabase.databasePath ?? "<not ready>")
            ValueRow(title: "Total Notes", value: String(notesCount))
        }

        Section("Insert") {
            TextField("Note title", text: $newTitle)
                #if os(iOS)
                    .textInputAutocapitalization(.sentences)
                #endif
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
            ForEach(notes, id: \.id) { note in
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
        .onAppear {
            startObservation()
        }
    }

    private func startObservation() {
        let observation = ValueObservation.tracking { db -> ([DemoNote], Int) in
            let notes =
                try DemoNote
                .order(DemoNote.Columns.createdAtUTC)
                .fetchAll(db)
            let count = try DemoNote.fetchCount(db)
            return (notes, count)
        }

        observationCancellable = observation.start(
            in: database.reader,
            scheduling: .async(onQueue: .main)
        ) { error in
            preconditionFailure("Database observation failed: \(error)")
        } onChange: { (fetchedNotes, count) in
            notes = fetchedNotes
            notesCount = count
        }
    }

    private func insertNote() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let utcString = UTCDateFormatter.iso8601String(from: Date())

        do {
            var note = DemoNote(id: nil, title: trimmed, createdAtUTC: utcString)
            try database.saveNote(&note)

            guard let insertedID = note.id else {
                preconditionFailure("GRDB insert returned nil ID")
            }

            lastInsertedID = String(insertedID)
            lastInsertedUTC = utcString
            newTitle = ""
        } catch {
            preconditionFailure("GRDB insert failed: \(error)")
        }
    }

    private func deleteAllNotes() {
        do {
            try database.deleteAllNotes()
            lastInsertedID = ""
            lastInsertedUTC = ""
        } catch {
            preconditionFailure("GRDB delete failed: \(error)")
        }
    }
}
