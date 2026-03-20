//
//  FileDestination.swift
//

import Foundation

public final class FileDestination: LogDestination, @unchecked Sendable {
    public let minimumLevel: LogLevel
    public let fileURL: URL
    public let directory: URL
    public let prefix: String

    private let queue: DispatchQueue
    private let fileHandle: FileHandle
    private let dateFormatter: ISO8601DateFormatter

    public init(
        directory: URL = .cachesDirectory.appending(path: "Logs"),
        prefix: String = "app",
        maxFileCount: Int = 10,
        minimumLevel: LogLevel = .debug
    ) {
        self.minimumLevel = minimumLevel
        self.directory = directory
        self.prefix = prefix
        self.queue = DispatchQueue(label: "dev.rocry.rckit.file-log", qos: .utility)
        self.dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // Generate filename with launch timestamp
        let timestamp = Self.launchTimestamp
        let filename = "\(prefix)-\(timestamp).log"
        self.fileURL = directory.appending(path: filename)

        // Create file if needed
        if !FileManager.default.fileExists(atPath: fileURL.path()) {
            FileManager.default.createFile(atPath: fileURL.path(), contents: nil)
        }

        // Open file handle for appending
        do {
            self.fileHandle = try FileHandle(forWritingTo: fileURL)
            try fileHandle.seekToEnd()
        } catch {
            preconditionFailure("FileDestination: Failed to open log file at \(fileURL.path()): \(error)")
        }

        // Cleanup old files
        Self.cleanupOldFiles(in: directory, prefix: prefix, keeping: maxFileCount)
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
        guard level >= minimumLevel else { return }

        let timestamp = dateFormatter.string(from: Date())
        let logLine = "[\(timestamp)] [\(level.label)] [\(category)] \(message) (\(file)#\(line) \(function))\n"

        queue.async { [weak self] in
            guard let self, let data = logLine.data(using: .utf8) else { return }
            try? self.fileHandle.write(contentsOf: data)
        }
    }

    // MARK: - Reading

    /// All log file URLs in chronological order (oldest first).
    public func allLogFileURLs() -> [URL] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey]) else {
            return []
        }
        return files
            .filter { $0.lastPathComponent.hasPrefix(prefix) && $0.pathExtension == "log" }
            .sorted { url1, url2 in
                let d1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let d2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return d1 < d2
            }
    }

    /// Concatenated content of all log files (previous sessions + current), chronological order.
    public func readAllContent() -> String {
        // Flush current writes before reading
        queue.sync {}

        return allLogFileURLs().compactMap { url in
            try? String(contentsOf: url, encoding: .utf8)
        }.joined()
    }

    // MARK: - Private

    private static let launchTimestamp: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        formatter.timeZone = .gmt
        return formatter.string(from: Date())
    }()

    private static func cleanupOldFiles(in directory: URL, prefix: String, keeping maxCount: Int) {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }

        // Filter to matching log files
        let logFiles =
            files
            .filter { $0.lastPathComponent.hasPrefix(prefix) && $0.pathExtension == "log" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return date1 > date2  // newest first
            }

        // Remove excess files
        if logFiles.count > maxCount {
            for file in logFiles.dropFirst(maxCount) {
                try? fm.removeItem(at: file)
            }
        }
    }
}
