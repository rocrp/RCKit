import Foundation
import Synchronization
import Testing

@testable import RCKit

struct FileDestinationTests {
    @Test func injectedClockControlsFilenameAndLineTimestampWithoutRegating() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let launchDate = try date("2024-01-02T03:04:05Z")
        let lineDate = try date("2024-01-02T03:05:06Z")
        let clock = TestClock(dates: [launchDate, lineDate])
        let destination = try FileDestination(
            directory: directory,
            prefix: "unit",
            minimumLevel: .fault,
            now: clock.now
        )

        destination.send(
            level: .debug,
            message: "ready",
            subsystem: "com.example.app",
            category: "network",
            file: "Sources/App.swift",
            line: 42,
            function: "start()"
        )

        #expect(destination.fileURL == directory.appending(path: "unit-2024-01-02-030405.log"))
        let content = try await destination.readAllContent()
        #expect(
            content == """
                [2024-01-02T03:05:06] [DEBUG] [network] ready (Sources/App.swift#42 start())

                """
        )
    }

    @Test func retentionRemovesOldestMatchingSessionsAndKeepsNewest() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        for name in [
            "unit-2024-01-05-000000.log",
            "unit-2024-01-01-000000.log",
            "unit-2024-01-04-000000.log",
            "unit-2024-01-02-000000.log",
            "unit-2024-01-03-000000.log",
        ] {
            try name.write(to: directory.appending(path: name), atomically: true, encoding: .utf8)
        }
        try "unrelated".write(
            to: directory.appending(path: "other-2023-01-01-000000.log"),
            atomically: true,
            encoding: .utf8
        )

        let currentDate = try date("2024-01-06T00:00:00Z")
        let destination = try FileDestination(
            directory: directory,
            prefix: "unit",
            maxFileCount: 3,
            now: { currentDate }
        )

        #expect(
            try destination.allLogFileURLs().map(\.lastPathComponent) == [
                "unit-2024-01-04-000000.log",
                "unit-2024-01-05-000000.log",
                "unit-2024-01-06-000000.log",
            ]
        )
        #expect(FileManager.default.fileExists(atPath: directory.appending(path: "other-2023-01-01-000000.log").path()))
    }

    @Test func readAllContentConcatenatesSessionsChronologicallyAndFlushesPendingWrite() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        try "first\n".write(
            to: directory.appending(path: "unit-2024-01-01-000000.log"),
            atomically: true,
            encoding: .utf8
        )
        try "second\n".write(
            to: directory.appending(path: "unit-2024-01-02-000000.log"),
            atomically: true,
            encoding: .utf8
        )
        try "ignored\n".write(
            to: directory.appending(path: "unit-2024-01-00-000000.txt"),
            atomically: true,
            encoding: .utf8
        )

        let fixedDate = try date("2024-01-03T00:00:00Z")
        let destination = try FileDestination(
            directory: directory,
            prefix: "unit",
            now: { fixedDate }
        )
        destination.send(
            level: .info,
            message: "third",
            subsystem: "com.example.app",
            category: "startup",
            file: "App.swift",
            line: 7,
            function: "launch()"
        )

        let content = try await destination.readAllContent()
        #expect(
            content == """
                first
                second
                [2024-01-03T00:00:00] [INFO] [startup] third (App.swift#7 launch())

                """
        )
    }

    @Test func initThrowsClearErrorWhenLogFileCannotBeOpened() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let fixedDate = try date("2024-01-02T03:04:05Z")
        let fileURL = directory.appending(path: "unit-2024-01-02-030405.log")
        try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)

        do {
            _ = try FileDestination(
                directory: directory,
                prefix: "unit",
                now: { fixedDate }
            )
            Issue.record("Expected FileDestination initialization to fail")
        } catch let error as FileDestinationError {
            guard case .openFileFailed(let failedURL, _) = error else {
                Issue.record("Unexpected FileDestination error: \(error)")
                return
            }
            #expect(failedURL == fileURL)
            #expect(error.localizedDescription.contains(fileURL.path()))
        }
    }
}

private final class TestClock: Sendable {
    private let dates: Mutex<[Date]>

    init(dates: [Date]) {
        self.dates = Mutex(dates)
    }

    func now() -> Date {
        dates.withLock { dates in
            precondition(!dates.isEmpty, "TestClock exhausted")
            return dates.removeFirst()
        }
    }
}

private func temporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

private func date(_ value: String) throws -> Date {
    let formatter = ISO8601DateFormatter()
    return try #require(formatter.date(from: value))
}
