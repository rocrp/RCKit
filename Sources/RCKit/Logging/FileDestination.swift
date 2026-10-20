//
//  FileDestination.swift
//

import Foundation

public enum FileDestinationError: LocalizedError {
    case invalidMaxTotalBytes(Int)
    case createDirectoryFailed(URL, underlying: any Error)
    case createFileFailed(URL)
    case openFileFailed(URL, underlying: any Error)
    case listFilesFailed(URL, underlying: any Error)
    case cleanupFailed(URL, underlying: any Error)
    case writeFailed(URL, underlying: any Error)
    case synchronizeFailed(URL, underlying: any Error)

    public var errorDescription: String? {
        switch self {
        case .invalidMaxTotalBytes(let bytes):
            "FileDestination maxTotalBytes must be greater than zero; received \(bytes)"
        case .createDirectoryFailed(let url, let error):
            "FileDestination could not create log directory at \(url.path(percentEncoded: false)): \(error.localizedDescription)"
        case .createFileFailed(let url):
            "FileDestination could not create log file at \(url.path(percentEncoded: false))"
        case .openFileFailed(let url, let error):
            "FileDestination could not open log file at \(url.path(percentEncoded: false)): \(error.localizedDescription)"
        case .listFilesFailed(let url, let error):
            "FileDestination could not list log files in \(url.path(percentEncoded: false)): \(error.localizedDescription)"
        case .cleanupFailed(let url, let error):
            "FileDestination could not remove old log file at \(url.path(percentEncoded: false)): \(error.localizedDescription)"
        case .writeFailed(let url, let error):
            "FileDestination could not write log file at \(url.path(percentEncoded: false)): \(error.localizedDescription)"
        case .synchronizeFailed(let url, let error):
            "FileDestination could not synchronize log file at \(url.path(percentEncoded: false)): \(error.localizedDescription)"
        }
    }
}

/// Writes log lines to `<prefix>-yyyy-MM-dd-HHmmss-SSS.log` files (UTC) in `directory`, bounded by total size.
///
/// Each launch starts a new file. Within a launch, once the current file reaches `maxTotalBytes / 4`,
/// the next line starts another file. Whenever a file starts, the oldest matching files (never the
/// current one, never files without the `<prefix>-` / `.log` shape) are deleted until all matching
/// files total at most `maxTotalBytes`. Disk use therefore peaks at `maxTotalBytes` plus the current
/// file (`maxTotalBytes / 4` plus one line).
///
/// All file work runs on one serial queue. The first write, roll or cleanup failure is kept and
/// thrown by `readAllContent()`.
public final class FileDestination: LogDestination, @unchecked Sendable {
    public let minimumLevel: LogLevel
    public let directory: URL
    public let prefix: String
    public let maxTotalBytes: Int

    private let rollBytes: Int
    private let queue: DispatchQueue
    private let dateFormatter: ISO8601DateFormatter
    private let now: @Sendable () -> Date

    // Owned by `queue` after init.
    private var currentURL: URL
    private var fileHandle: FileHandle
    private var currentBytes = 0
    private var writeError: (any Error)?

    public init(
        directory: URL = .cachesDirectory.appending(path: "Logs"),
        prefix: String = "app",
        maxTotalBytes: Int = 4 * 1024 * 1024,
        minimumLevel: LogLevel = .debug,
        now: @escaping @Sendable () -> Date = Date.init
    ) throws {
        guard maxTotalBytes > 0 else {
            throw FileDestinationError.invalidMaxTotalBytes(maxTotalBytes)
        }

        self.minimumLevel = minimumLevel
        self.directory = directory
        self.prefix = prefix
        self.maxTotalBytes = maxTotalBytes
        self.rollBytes = maxTotalBytes / 4
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

        (currentURL, fileHandle) = try Self.startFile(
            in: directory,
            prefix: prefix,
            maxTotalBytes: maxTotalBytes,
            date: now()
        )
    }

    deinit {
        try? fileHandle.close()
    }

    /// The file the next line goes to. Changes when the launch rolls to a new file.
    public var fileURL: URL {
        queue.sync { currentURL }
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
            let data = Data(logLine.utf8)

            do {
                if self.currentBytes >= self.rollBytes {
                    try self.roll(date: date)
                }
                try self.fileHandle.write(contentsOf: data)
                self.currentBytes += data.count
            } catch {
                self.writeError = self.writeError ?? error
            }
        }
    }

    /// All matching log files in chronological order, oldest first.
    public func allLogFileURLs() throws -> [URL] {
        try Self.matchingLogFiles(in: directory, prefix: prefix)
    }

    /// Concatenated content of all matching files in chronological order.
    ///
    /// Pending writes are synchronized before files are read.
    public func readAllContent() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    if let writeError = self.writeError {
                        throw FileDestinationError.writeFailed(self.currentURL, underlying: writeError)
                    }

                    do {
                        try self.fileHandle.synchronize()
                    } catch {
                        throw FileDestinationError.synchronizeFailed(self.currentURL, underlying: error)
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

    /// Runs on `queue`.
    private func roll(date: Date) throws {
        let (url, handle) = try Self.startFile(
            in: directory,
            prefix: prefix,
            maxTotalBytes: maxTotalBytes,
            date: date
        )
        try? fileHandle.close()
        currentURL = url
        fileHandle = handle
        currentBytes = 0
    }

    /// Creates the next free `<prefix>-<timestamp>.log`, trims old files, and opens it.
    private static func startFile(
        in directory: URL,
        prefix: String,
        maxTotalBytes: Int,
        date: Date
    ) throws -> (URL, FileHandle) {
        var milliseconds = Int64((date.timeIntervalSince1970 * 1000).rounded(.down))
        var fileURL = directory.appending(path: filename(prefix: prefix, milliseconds: milliseconds))
        while FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) {
            milliseconds += 1
            fileURL = directory.appending(path: filename(prefix: prefix, milliseconds: milliseconds))
        }

        guard FileManager.default.createFile(atPath: fileURL.path(percentEncoded: false), contents: nil) else {
            throw FileDestinationError.createFileFailed(fileURL)
        }

        try trim(in: directory, prefix: prefix, maxTotalBytes: maxTotalBytes, keeping: fileURL)

        do {
            return (fileURL, try FileHandle(forWritingTo: fileURL))
        } catch {
            throw FileDestinationError.openFileFailed(fileURL, underlying: error)
        }
    }

    private static func filename(prefix: String, milliseconds: Int64) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let seconds = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000)))
        let fraction = String(format: "%03d", Int(milliseconds % 1000))
        return "\(prefix)-\(seconds)-\(fraction).log"
    }

    /// Matching files sorted by name; the fixed-width UTC timestamp makes that chronological.
    private static func matchingLogFiles(in directory: URL, prefix: String) throws -> [URL] {
        let files: [URL]
        do {
            files = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey]
            )
        } catch {
            throw FileDestinationError.listFilesFailed(directory, underlying: error)
        }
        let filenamePrefix = "\(prefix)-"

        return try files.filter { url in
            guard url.lastPathComponent.hasPrefix(filenamePrefix), url.pathExtension == "log" else {
                return false
            }
            return try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true
        }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func trim(in directory: URL, prefix: String, maxTotalBytes: Int, keeping current: URL) throws {
        let files = try matchingLogFiles(in: directory, prefix: prefix)
        let sizes = try files.map { url in
            guard let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
                preconditionFailure("FileDestination could not read size of \(url.path(percentEncoded: false))")
            }
            return size
        }
        var total = sizes.reduce(0, +)

        for (file, size) in zip(files, sizes) where total > maxTotalBytes {
            guard file.lastPathComponent != current.lastPathComponent else { continue }
            do {
                try FileManager.default.removeItem(at: file)
            } catch {
                throw FileDestinationError.cleanupFailed(file, underlying: error)
            }
            total -= size
        }
    }
}
