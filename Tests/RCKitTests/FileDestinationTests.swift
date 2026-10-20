import Foundation
import Synchronization
import Testing

@testable import RCKit

struct FileDestinationTests {
    @Test func injectedClockControlsFilenameAndLineTimestampWithoutRegating() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let launchDate = try date("2024-01-02T03:04:05.678Z")
        let lineDate = try date("2024-01-02T03:05:06.000Z")
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

        #expect(destination.fileURL == directory.appending(path: "unit-2024-01-02-030405-678.log"))
        let content = try await destination.readAllContent()
        #expect(
            content == """
                [2024-01-02T03:05:06] [DEBUG] [network] ready (Sources/App.swift#42 start())

                """
        )
    }

    @Test func existingFilenameStepsForwardOneMillisecond() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        try "old\n".write(
            to: directory.appending(path: "unit-2024-01-02-030405-250.log"),
            atomically: true,
            encoding: .utf8
        )

        let launchDate = try date("2024-01-02T03:04:05.250Z")
        let destination = try FileDestination(directory: directory, prefix: "unit", now: { launchDate })

        #expect(destination.fileURL == directory.appending(path: "unit-2024-01-02-030405-251.log"))
    }

    @Test func startRemovesOldestMatchingFilesUntilTotalFitsCap() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        // 150 + 100 + 120 + 90 = 460 bytes > 300: dropping 150 leaves 310, dropping 100 more leaves 210.
        for (name, size) in [
            ("unit-2024-01-04-000000-000.log", 90),
            ("unit-2024-01-01-000000-000.log", 150),
            ("unit-2024-01-03-000000-000.log", 120),
            ("unit-2024-01-02-000000-000.log", 100),
        ] {
            try String(repeating: "x", count: size).write(
                to: directory.appending(path: name),
                atomically: true,
                encoding: .utf8
            )
        }
        try String(repeating: "u", count: 1000).write(
            to: directory.appending(path: "other-2023-01-01-000000-000.log"),
            atomically: true,
            encoding: .utf8
        )

        let currentDate = try date("2024-01-06T00:00:00.000Z")
        let destination = try FileDestination(
            directory: directory,
            prefix: "unit",
            maxTotalBytes: 300,
            now: { currentDate }
        )

        #expect(
            try destination.allLogFileURLs().map(\.lastPathComponent) == [
                "unit-2024-01-03-000000-000.log",
                "unit-2024-01-04-000000-000.log",
                "unit-2024-01-06-000000-000.log",
            ]
        )
        #expect(FileManager.default.fileExists(atPath: directory.appending(path: "other-2023-01-01-000000-000.log").path(percentEncoded: false)))
    }

    @Test func longLaunchRollsAtQuarterCapAndDropsItsOwnOldestFile() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        // Every line below is exactly 100 bytes; cap 400 rolls at 100, so each line after the first
        // starts a file named by its own timestamp. Starting the sixth file makes 500 bytes: the
        // launch's first file goes.
        let lineDates = try (6...11).map { try date("2024-01-02T03:04:\(String(format: "%02d", $0)).000Z") }
        let clock = TestClock(dates: [try date("2024-01-02T03:04:05.250Z")] + lineDates)
        let destination = try FileDestination(
            directory: directory,
            prefix: "unit",
            maxTotalBytes: 400,
            minimumLevel: .debug,
            now: clock.now
        )

        for n in 1...6 {
            destination.send(
                level: .info,
                message: "\(n)" + String(repeating: "x", count: 57),
                subsystem: "s",
                category: "c",
                file: "f",
                line: 1,
                function: "g"
            )
        }

        let content = try await destination.readAllContent()
        #expect(
            try destination.allLogFileURLs().map(\.lastPathComponent) == [
                "unit-2024-01-02-030407-000.log",
                "unit-2024-01-02-030408-000.log",
                "unit-2024-01-02-030409-000.log",
                "unit-2024-01-02-030410-000.log",
                "unit-2024-01-02-030411-000.log",
            ]
        )
        #expect(destination.fileURL == directory.appending(path: "unit-2024-01-02-030411-000.log"))
        let xs = String(repeating: "x", count: 57)
        #expect(
            content == """
                [2024-01-02T03:04:07] [INFO] [c] 2\(xs) (f#1 g)
                [2024-01-02T03:04:08] [INFO] [c] 3\(xs) (f#1 g)
                [2024-01-02T03:04:09] [INFO] [c] 4\(xs) (f#1 g)
                [2024-01-02T03:04:10] [INFO] [c] 5\(xs) (f#1 g)
                [2024-01-02T03:04:11] [INFO] [c] 6\(xs) (f#1 g)

                """
        )
    }

    @Test func readAllContentConcatenatesFilesChronologicallyAndFlushesPendingWrite() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        try "first\n".write(
            to: directory.appending(path: "unit-2024-01-01-000000-000.log"),
            atomically: true,
            encoding: .utf8
        )
        try "second\n".write(
            to: directory.appending(path: "unit-2024-01-02-000000-000.log"),
            atomically: true,
            encoding: .utf8
        )
        try "ignored\n".write(
            to: directory.appending(path: "unit-2024-01-00-000000-000.txt"),
            atomically: true,
            encoding: .utf8
        )

        let fixedDate = try date("2024-01-03T00:00:00.000Z")
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

    @Test func initRejectsNonPositiveCap() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(throws: FileDestinationError.self) {
            try FileDestination(directory: directory, maxTotalBytes: 0)
        }
    }

    @Test func initThrowsClearErrorWhenLogFileCannotBeCreated() throws {
        let directory = try temporaryDirectory()
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory.path(percentEncoded: false))
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path(percentEncoded: false))
            try? FileManager.default.removeItem(at: directory)
        }

        let fixedDate = try date("2024-01-02T03:04:05.000Z")
        let fileURL = directory.appending(path: "unit-2024-01-02-030405-000.log")

        do {
            _ = try FileDestination(
                directory: directory,
                prefix: "unit",
                now: { fixedDate }
            )
            Issue.record("Expected FileDestination initialization to fail")
        } catch let error as FileDestinationError {
            guard case .createFileFailed(let failedURL) = error else {
                Issue.record("Unexpected FileDestination error: \(error)")
                return
            }
            #expect(failedURL == fileURL)
            #expect(error.localizedDescription.contains(fileURL.path(percentEncoded: false)))
        }
    }

    /// iOS's Application Support has a space in its name; `URL.path()` percent-encodes it,
    /// and a FileManager call given `Application%20Support` created no file (seen on the
    /// simulator: "could not create log file at …/Application%20Support/Logs/…").
    @Test func aDirectoryWithASpaceInItsPathTakesLines() async throws {
        let parent = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parent) }
        let directory = parent.appending(path: "Application Support/Logs", directoryHint: .isDirectory)

        let destination = try FileDestination(directory: directory, prefix: "unit", now: { Date(timeIntervalSince1970: 0) })
        destination.send(
            level: .notice,
            message: "ready",
            subsystem: "com.example.app",
            category: "app",
            file: "App.swift",
            line: 1,
            function: "f()"
        )

        #expect(try await destination.readAllContent() == "[1970-01-01T00:00:00] [NOTICE] [app] ready (App.swift#1 f())\n")
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
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return try #require(formatter.date(from: value))
}
