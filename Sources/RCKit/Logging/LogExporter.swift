//
//  LogExporter.swift
//

import Foundation
import OSLog

public struct LogEntry: Equatable, Sendable {
    public let date: Date
    public let level: LogLevel
    public let subsystem: String
    public let category: String
    public let message: String

    public init(
        date: Date,
        level: LogLevel,
        subsystem: String,
        category: String,
        message: String
    ) {
        self.date = date
        self.level = level
        self.subsystem = subsystem
        self.category = category
        self.message = message
    }
}

public struct LogStorePredicate: Sendable {
    private let subsystem: String?
    private let categories: [String]?

    init(subsystem: String?, categories: [String]?) {
        self.subsystem = subsystem
        self.categories = categories
    }

    public var foundationValue: NSPredicate {
        var format = "eventType == 'logEvent'"
        var arguments: [Any] = []

        if let subsystem {
            format += " && subsystem == %@"
            arguments.append(subsystem)
        }

        if let categories, !categories.isEmpty {
            format += " && category IN %@"
            arguments.append(categories)
        }

        return NSPredicate(format: format, argumentArray: arguments)
    }
}

/// Historical log records consumed by ``LogExporter``.
///
/// Implementations receive a fully assembled predicate. A Log Store only queries and maps records;
/// filtering and formatting decisions belong to the exporter. Because OSLog has no warning archive
/// level, warnings written as `.error` are returned as ``LogLevel/error``.
public protocol LogStore: Sendable {
    func entries(since: Date, matching predicate: LogStorePredicate) async throws -> [LogEntry]
}

public enum LogStoreError: Error {
    case unavailable(underlying: any Error)
    case unexpectedEntry(String)
}

/// The system Log Store adapter. It maps `OSLogStore` records into owned ``LogEntry`` values.
public struct SystemLogStore: LogStore {
    private static let queue = DispatchQueue(label: "dev.rocry.rckit.system-log-store", qos: .utility)

    public init() {}

    public func entries(since: Date, matching predicate: LogStorePredicate) async throws -> [LogEntry] {
        try await withCheckedThrowingContinuation { continuation in
            Self.queue.async {
                do {
                    continuation.resume(returning: try Self.loadEntries(since: since, matching: predicate.foundationValue))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func loadEntries(since: Date, matching predicate: NSPredicate) throws -> [LogEntry] {
        let store: OSLogStore
        do {
            store = try OSLogStore(scope: .currentProcessIdentifier)
        } catch {
            throw LogStoreError.unavailable(underlying: error)
        }

        let position = store.position(date: since)
        return try store.getEntries(at: position, matching: predicate).map { entry in
            guard let logEntry = entry as? OSLogEntryLog else {
                throw LogStoreError.unexpectedEntry(String(describing: type(of: entry)))
            }

            return LogEntry(
                date: entry.date,
                level: LogLevel(from: logEntry.level),
                subsystem: logEntry.subsystem,
                category: logEntry.category,
                message: entry.composedMessage
            )
        }
    }
}

public struct LogExporter: Sendable {
    private static let exportQueue = DispatchQueue(label: "dev.rocry.rckit.log-export", qos: .utility)

    public enum ExportError: Error {
        case storeUnavailable
        case exportFailed(underlying: any Error)
    }

    private let store: any LogStore
    private let destinationDirectory: URL
    private let now: @Sendable () -> Date

    public init(
        store: any LogStore = SystemLogStore(),
        destinationDirectory: URL = FileManager.default.temporaryDirectory,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.store = store
        self.destinationDirectory = destinationDirectory
        self.now = now
    }

    @concurrent
    public func fetch(
        since: Date,
        subsystem: String? = nil,
        categories: [String]? = nil,
        levels: [LogLevel]? = nil
    ) async throws -> [LogEntry] {
        try Task.checkCancellation()

        let entries: [LogEntry]
        do {
            entries = try await store.entries(
                since: since,
                matching: Self.predicate(subsystem: subsystem, categories: categories)
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch LogStoreError.unavailable {
            throw ExportError.storeUnavailable
        } catch {
            throw ExportError.exportFailed(underlying: error)
        }

        return try entries.filter { entry in
            try Task.checkCancellation()
            return levels?.contains(entry.level) ?? true
        }
    }

    @concurrent
    public func exportToFile(
        since: Date,
        subsystem: String? = nil
    ) async throws -> URL {
        let entries = try await fetch(since: since, subsystem: subsystem)
        let formatter = Self.makeDateFormatter()
        let content =
            entries.map { entry in
                let timestamp = formatter.string(from: entry.date)
                return "[\(timestamp)] [\(entry.level.label)] [\(entry.subsystem):\(entry.category)] \(entry.message)"
            }.joined(separator: "\n") + (entries.isEmpty ? "" : "\n")

        let filename = "logs-\(formatter.string(from: now())).txt"
        let url = destinationDirectory.appending(path: filename)

        do {
            try await Self.write(content: content, to: url)
        } catch {
            throw ExportError.exportFailed(underlying: error)
        }
        return url
    }

    static func predicate(subsystem: String?, categories: [String]?) -> LogStorePredicate {
        LogStorePredicate(subsystem: subsystem, categories: categories)
    }

    private static func makeDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        return formatter
    }

    private static func write(content: String, to url: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            exportQueue.async {
                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension LogLevel {
    init(from osLogLevel: OSLogEntryLog.Level) {
        switch osLogLevel {
        case .debug: self = .debug
        case .info: self = .info
        case .notice: self = .notice
        case .error: self = .error
        case .fault: self = .fault
        case .undefined: self = .debug
        @unknown default: self = .debug
        }
    }
}
