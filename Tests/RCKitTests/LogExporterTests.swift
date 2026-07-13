import Foundation
import OSLog
import Synchronization
import Testing

@testable import RCKit

struct LogExporterTests {
    @Test func fetchFiltersSubsystemCategoriesAndLevels() async throws {
        let since = Date(timeIntervalSince1970: 1_700_000_000)
        let store = FakeLogStore(
            entries: [
                entry(level: .error, subsystem: "com.example.app", category: "network", message: "kept"),
                entry(level: .info, subsystem: "com.example.app", category: "network", message: "wrong level"),
                entry(level: .error, subsystem: "com.example.app", category: "database", message: "wrong category"),
                entry(level: .error, subsystem: "com.example.other", category: "network", message: "wrong subsystem"),
            ]
        )
        let exporter = LogExporter(store: store)

        let entries = try await exporter.fetch(
            since: since,
            subsystem: "com.example.app",
            categories: ["network"],
            levels: [.error]
        )

        #expect(entries == [entry(level: .error, subsystem: "com.example.app", category: "network", message: "kept")])
        #expect(store.receivedSince == since)
    }

    @Test func predicateWithoutFiltersMatchesEveryLogEvent() {
        let predicate = LogExporter.predicate(subsystem: nil, categories: nil)

        #expect(predicate.foundationValue.evaluate(with: predicateEntry(subsystem: "a", category: "one")))
        #expect(
            predicate.foundationValue.evaluate(
                with: predicateEntry(eventType: "signpostEvent", subsystem: "a", category: "one")
            ) == false
        )
    }

    @Test func predicateFiltersSubsystemOnly() {
        let predicate = LogExporter.predicate(subsystem: "com.example.app", categories: nil)

        #expect(predicate.foundationValue.evaluate(with: predicateEntry(subsystem: "com.example.app", category: "one")))
        #expect(predicate.foundationValue.evaluate(with: predicateEntry(subsystem: "com.example.other", category: "one")) == false)
    }

    @Test func predicateFiltersCategoriesOnly() {
        let predicate = LogExporter.predicate(subsystem: nil, categories: ["network", "database"])

        #expect(predicate.foundationValue.evaluate(with: predicateEntry(subsystem: "a", category: "network")))
        #expect(predicate.foundationValue.evaluate(with: predicateEntry(subsystem: "a", category: "ui")) == false)
    }

    @Test func predicateFiltersSubsystemAndCategories() {
        let predicate = LogExporter.predicate(subsystem: "com.example.app", categories: ["network"])

        #expect(predicate.foundationValue.evaluate(with: predicateEntry(subsystem: "com.example.app", category: "network")))
        #expect(
            predicate.foundationValue.evaluate(with: predicateEntry(subsystem: "com.example.other", category: "network")) == false
        )
        #expect(predicate.foundationValue.evaluate(with: predicateEntry(subsystem: "com.example.app", category: "ui")) == false)
    }

    @Test func mapsEverySystemLogLevel() {
        #expect(LogLevel(from: OSLogEntryLog.Level.debug) == .debug)
        #expect(LogLevel(from: OSLogEntryLog.Level.info) == .info)
        #expect(LogLevel(from: OSLogEntryLog.Level.notice) == .notice)
        #expect(LogLevel(from: OSLogEntryLog.Level.error) == .error)
        #expect(LogLevel(from: OSLogEntryLog.Level.fault) == .fault)
        #expect(LogLevel(from: OSLogEntryLog.Level.undefined) == .debug)
    }

    @Test func warningRoundTripIsLossyBecauseOSLogHasNoWarningLevel() {
        #expect(LogLevel.warning.osLogType == .error)
        #expect(LogLevel.warning.osLogType == LogLevel.error.osLogType)
        #expect(LogLevel(from: OSLogEntryLog.Level.error) == .error)
    }

    @Test func exportToFileUsesInjectedDirectoryAndClock() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let firstDate = Date(timeIntervalSince1970: 1_704_165_845)
        let secondDate = Date(timeIntervalSince1970: 1_704_165_906)
        let store = FakeLogStore(
            entries: [
                LogEntry(
                    date: firstDate,
                    level: .info,
                    subsystem: "com.example.app",
                    category: "startup",
                    message: "ready"
                ),
                LogEntry(
                    date: secondDate,
                    level: .error,
                    subsystem: "com.example.app",
                    category: "network",
                    message: "offline"
                ),
            ]
        )
        let exporter = LogExporter(
            store: store,
            destinationDirectory: directory,
            now: { firstDate }
        )

        let url = try await exporter.exportToFile(since: .distantPast, subsystem: "com.example.app")

        #expect(url == directory.appending(path: "logs-2024-01-02T03:24:05.txt"))
        #expect(
            try String(contentsOf: url, encoding: .utf8) == """
                [2024-01-02T03:24:05] [INFO] [com.example.app:startup] ready
                [2024-01-02T03:25:06] [ERROR] [com.example.app:network] offline

                """
        )
    }
}

private final class FakeLogStore: LogStore {
    private struct State {
        var receivedSince: Date?
    }

    private let entries: [LogEntry]
    private let state = Mutex(State())

    var receivedSince: Date? {
        state.withLock { $0.receivedSince }
    }

    init(entries: [LogEntry]) {
        self.entries = entries
    }

    func entries(since: Date, matching predicate: LogStorePredicate) async throws -> [LogEntry] {
        state.withLock { $0.receivedSince = since }
        return entries.filter { entry in
            predicate.foundationValue.evaluate(
                with: predicateEntry(subsystem: entry.subsystem, category: entry.category)
            )
        }
    }
}

private func entry(
    level: LogLevel,
    subsystem: String,
    category: String,
    message: String
) -> LogEntry {
    LogEntry(
        date: Date(timeIntervalSince1970: 1_700_000_001),
        level: level,
        subsystem: subsystem,
        category: category,
        message: message
    )
}

private func predicateEntry(
    eventType: String = "logEvent",
    subsystem: String,
    category: String
) -> [String: String] {
    [
        "eventType": eventType,
        "subsystem": subsystem,
        "category": category,
    ]
}
