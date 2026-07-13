//
//  FileDestination.swift
//

import Foundation

public enum FileDestinationError: LocalizedError {
    case invalidMaxFileCount(Int)
    case createDirectoryFailed(URL, underlying: any Error)
    case createFileFailed(URL)
    case openFileFailed(URL, underlying: any Error)
    case cleanupFailed(URL, underlying: any Error)
    case writeFailed(URL, underlying: any Error)
    case synchronizeFailed(URL, underlying: any Error)

    public var errorDescription: String? {
        switch self {
        case .invalidMaxFileCount(let count):
            "FileDestination maxFileCount must be greater than zero; received \(count)"
        case .createDirectoryFailed(let url, let error):
            "FileDestination could not create log directory at \(url.path()): \(error.localizedDescription)"
        case .createFileFailed(let url):
            "FileDestination could not create log file at \(url.path())"
        case .openFileFailed(let url, let error):
            "FileDestination could not open log file at \(url.path()): \(error.localizedDescription)"
        case .cleanupFailed(let url, let error):
            "FileDestination could not remove old log file at \(url.path()): \(error.localizedDescription)"
        case .writeFailed(let url, let error):
            "FileDestination could not write log file at \(url.path()): \(error.localizedDescription)"
        case .synchronizeFailed(let url, let error):
            "FileDestination could not synchronize log file at \(url.path()): \(error.localizedDescription)"
        }
    }
}

public final class FileDestination: LogDestination, @unchecked Sendable {
    public let minimumLevel: LogLevel
    public let fileURL: URL
    public let directory: URL
    public let prefix: String

    private let queue: DispatchQueue
    private let fileHandle: FileHandle
    private let dateFormatter: ISO8601DateFormatter
    private let now: @Sendable () -> Date
    private var writeError: (any Error)?

    public init(
        directory: URL = .cachesDirectory.appending(path: "Logs"),
        prefix: String = "app",
        maxFileCount: Int = 10,
        minimumLevel: LogLevel = .debug,
        now: @escaping @Sendable () -> Date = Date.init
    ) throws {
        guard maxFileCount > 0 else {
            throw FileDestinationError.invalidMaxFileCount(maxFileCount)
        }

        self.minimumLevel = minimumLevel
        self.directory = directory
        self.prefix = prefix
        self.queue = DispatchQueue(label: "dev.rocry.rckit.file-log", qos: .utility)
        self.now = now

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        self.dateFormatter = dateFormatter

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw FileDestinationError.createDirectoryFailed(directory, underlying: error)
        }

        let filename = "\(prefix)-\(Self.filenameTimestamp(from: now())).log"
        let fileURL = directory.appending(path: filename)
        self.fileURL = fileURL

        if !FileManager.default.fileExists(atPath: fileURL.path()),
            !FileManager.default.createFile(atPath: fileURL.path(), contents: nil)
        {
            throw FileDestinationError.createFileFailed(fileURL)
        }

        try Self.cleanupOldFiles(in: directory, prefix: prefix, keeping: maxFileCount)

        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            try fileHandle.seekToEnd()
            self.fileHandle = fileHandle
        } catch {
            throw FileDestinationError.openFileFailed(fileURL, underlying: error)
        }
    }

    deinit {
        try? fileHandle.close()
    }

    public func send(
        level: LogLevel,
        message: String,
        subsystem: String,
        category: String,
        file: String,
        line: UInt,
        function: String
    ) {
        let date = now()

        queue.async {
            let timestamp = self.dateFormatter.string(from: date)
            let logLine = "[\(timestamp)] [\(level.label)] [\(category)] \(message) (\(file)#\(line) \(function))\n"

            do {
                try self.fileHandle.write(contentsOf: Data(logLine.utf8))
            } catch {
                self.writeError = self.writeError ?? error
            }
        }
    }

    /// All matching log files in chronological order, oldest first.
    public func allLogFileURLs() throws -> [URL] {
        try Self.matchingLogFiles(in: directory, prefix: prefix)
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Concatenated content of all sessions in chronological order.
    ///
    /// Pending writes to the current session are synchronized before files are read.
    public func readAllContent() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    if let writeError = self.writeError {
                        throw FileDestinationError.writeFailed(self.fileURL, underlying: writeError)
                    }

                    do {
                        try self.fileHandle.synchronize()
                    } catch {
                        throw FileDestinationError.synchronizeFailed(self.fileURL, underlying: error)
                    }

                    let content = try self.allLogFileURLs().map { url in
                        try String(contentsOf: url, encoding: .utf8)
                    }.joined()
                    continuation.resume(returning: content)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func filenameTimestamp(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: date)
    }

    private static func matchingLogFiles(in directory: URL, prefix: String) throws -> [URL] {
        let files = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey]
        )
        let filenamePrefix = "\(prefix)-"

        return try files.filter { url in
            guard url.lastPathComponent.hasPrefix(filenamePrefix), url.pathExtension == "log" else {
                return false
            }
            return try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true
        }
    }

    private static func cleanupOldFiles(in directory: URL, prefix: String, keeping maxCount: Int) throws {
        let logFiles = try matchingLogFiles(in: directory, prefix: prefix)
            .sorted { $0.lastPathComponent > $1.lastPathComponent }

        for file in logFiles.dropFirst(maxCount) {
            do {
                try FileManager.default.removeItem(at: file)
            } catch {
                throw FileDestinationError.cleanupFailed(file, underlying: error)
            }
        }
    }
}
