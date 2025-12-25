//
//  LogExporter.swift
//

import Foundation
import OSLog

public struct LogEntry: Sendable {
    public let date: Date
    public let level: LogLevel
    public let subsystem: String
    public let category: String
    public let message: String
}

public struct LogExporter: Sendable {
    public enum ExportError: Error {
        case storeUnavailable
        case exportFailed(underlying: any Error)
    }

    /// Fetch log entries from OSLogStore for current process
    public static func fetch(
        since: Date,
        subsystem: String? = nil,
        categories: [String]? = nil,
        levels: [LogLevel]? = nil
    ) async throws -> [LogEntry] {
        let store: OSLogStore
        do {
            store = try OSLogStore(scope: .currentProcessIdentifier)
        } catch {
            throw ExportError.storeUnavailable
        }

        let position = store.position(date: since)

        // Build predicate
        var predicateFormat = "eventType == 'logEvent'"
        var args: [Any] = []

        if let subsystem {
            predicateFormat += " && subsystem == %@"
            args.append(subsystem)
        }

        if let categories, !categories.isEmpty {
            predicateFormat += " && category IN %@"
            args.append(categories)
        }

        let predicate = NSPredicate(format: predicateFormat, argumentArray: args)

        do {
            let entries = try store.getEntries(at: position, matching: predicate)
            var result: [LogEntry] = []

            for entry in entries {
                try Task.checkCancellation()

                guard let logEntry = entry as? OSLogEntryLog else { continue }

                let level = LogLevel(from: logEntry.level)

                // Filter by level if specified
                if let levels, !levels.contains(level) {
                    continue
                }

                result.append(
                    LogEntry(
                        date: entry.date,
                        level: level,
                        subsystem: logEntry.subsystem,
                        category: logEntry.category,
                        message: entry.composedMessage
                    )
                )
            }

            return result
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw ExportError.exportFailed(underlying: error)
        }
    }

    /// Export logs to a temporary file, returns file URL
    public static func exportToFile(
        since: Date,
        subsystem: String? = nil
    ) async throws -> URL {
        let entries = try await fetch(since: since, subsystem: subsystem)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]

        var content = ""
        for entry in entries {
            let timestamp = formatter.string(from: entry.date)
            content += "[\(timestamp)] [\(entry.level.label)] [\(entry.subsystem):\(entry.category)] \(entry.message)\n"
        }

        let filename = "logs-\(formatter.string(from: Date())).txt"
        let url = FileManager.default.temporaryDirectory.appending(path: filename)

        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

// MARK: - LogLevel from OSLogEntryLog.Level

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
