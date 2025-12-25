//
//  Log.swift
//

import Foundation
import OSLog

private typealias SystemLogger = Logger

public struct Log: Sendable {
    // MARK: - Static Configuration

    private static let destinationsLock = NSLock()
    nonisolated(unsafe) private static var _destinations: [any LogDestination] = []

    public static func addDestination(_ destination: any LogDestination) {
        destinationsLock.withLock {
            _destinations.append(destination)
        }
    }

    public static func removeAllDestinations() {
        destinationsLock.withLock {
            _destinations.removeAll()
        }
    }

    private static var destinations: [any LogDestination] {
        destinationsLock.withLock { _destinations }
    }

    // MARK: - Default Logger

    /// Shared default logger instance
    public static let `default` = Log()

    // MARK: - Default Minimum Level

    public static let defaultMinimumLevel: LogLevel = {
        #if DEBUG
            return BuildConfig.isDebugging ? .debug : .info
        #else
            return .notice
        #endif
    }()

    // MARK: - Redaction

    public enum RedactionMode: Sendable {
        case none
        case common
        case keys(Set<String>)
    }

    private static let commonRedactionSubstrings: [String] = [
        "password", "passwd", "secret", "token", "apikey", "api_key",
        "authorization", "jwt", "session", "cookie", "credential", "bearer",
    ]

    // MARK: - Instance Properties

    private let osLogger: SystemLogger
    private let subsystem: String
    private let category: String
    private let minimumLevel: LogLevel
    private let redactionMode: RedactionMode

    // MARK: - Initialization

    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "dev.rocry.rckit",
        category: String = "general",
        minimumLevel: LogLevel = defaultMinimumLevel,
        redactionMode: RedactionMode = .common
    ) {
        self.subsystem = subsystem
        self.category = category
        self.minimumLevel = minimumLevel
        self.redactionMode = redactionMode
        self.osLogger = SystemLogger(subsystem: subsystem, category: category)
    }

    // MARK: - Core Logging

    public func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        metadata: [String: any CustomStringConvertible]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        guard level >= minimumLevel else { return }

        let composed = render(message(), metadata: metadata, file: file, line: line, function: function)

        // OSLog
        osLogger.log(level: level.osLogType, "\(composed, privacy: .public)")

        // Destinations
        for destination in Self.destinations where level >= destination.minimumLevel {
            destination.send(
                level: level,
                message: composed,
                subsystem: subsystem,
                category: category,
                file: file,
                line: line,
                function: function
            )
        }
    }

    // MARK: - Convenience Methods

    public func debug(
        _ message: @autoclosure () -> String,
        metadata: [String: any CustomStringConvertible]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.debug, message(), metadata: metadata, file: file, function: function, line: line)
    }

    public func info(
        _ message: @autoclosure () -> String,
        metadata: [String: any CustomStringConvertible]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.info, message(), metadata: metadata, file: file, function: function, line: line)
    }

    public func notice(
        _ message: @autoclosure () -> String,
        metadata: [String: any CustomStringConvertible]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.notice, message(), metadata: metadata, file: file, function: function, line: line)
    }

    public func warning(
        _ message: @autoclosure () -> String,
        metadata: [String: any CustomStringConvertible]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.warning, message(), metadata: metadata, file: file, function: function, line: line)
    }

    public func error(
        _ message: @autoclosure () -> String,
        metadata: [String: any CustomStringConvertible]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.error, message(), metadata: metadata, file: file, function: function, line: line)
    }

    public func error(
        _ message: @autoclosure () -> String,
        error: any Error,
        metadata: [String: any CustomStringConvertible]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        var meta = metadata ?? [:]
        meta["error"] = String(describing: error)
        log(.error, message(), metadata: meta, file: file, function: function, line: line)
    }

    public func fault(
        _ message: @autoclosure () -> String,
        metadata: [String: any CustomStringConvertible]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.fault, message(), metadata: metadata, file: file, function: function, line: line)
    }

    // MARK: - Rendering

    private func render(
        _ message: String,
        metadata: [String: any CustomStringConvertible]?,
        file: String,
        line: UInt,
        function: String
    ) -> String {
        let baseMessage: String
        if let metadata, !metadata.isEmpty {
            let metaString =
                metadata
                .sorted { $0.key < $1.key }
                .map { key, value in
                    let renderedValue = shouldRedact(key: key) ? "<redacted>" : String(describing: value)
                    return "\(key)=\(renderedValue)"
                }
                .joined(separator: " ")
            baseMessage = "\(message) [\(metaString)]"
        } else {
            baseMessage = message
        }

        // Extract filename from #fileID (e.g., "RCKit/Log.swift" → "Log.swift")
        let fileName = file.split(separator: "/").last.map(String.init) ?? file
        return "\(baseMessage) (\(fileName):\(line) \(function))"
    }

    private func shouldRedact(key: String) -> Bool {
        switch redactionMode {
        case .none:
            return false
        case .keys(let keys):
            let normalized = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return keys.contains { $0.lowercased() == normalized }
        case .common:
            let normalized = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return Self.commonRedactionSubstrings.contains { normalized.contains($0) }
        }
    }
}

// MARK: - Debug Info

extension Log {
    public func printDebugInfo() {
        info(
            """
            ---------------- Debug Info ----------------
            isDebugging: \(BuildConfig.isDebugging)
            isDebugOrTestFlight: \(BuildConfig.isDebugOrTestFlight)
            channelName: \(BuildConfig.channelName)
            allowDebug: \(BuildConfig.allowDebug)
            Bundle.identifier: \(BuildConfig.Bundle.identifier)
            Bundle.shortVersion: \(BuildConfig.Bundle.shortVersion)
            Bundle.version: \(BuildConfig.Bundle.version)
            Bundle.displayName: \(BuildConfig.Bundle.displayName)
            Bundle.bundleName: \(BuildConfig.Bundle.bundleName)
            ---------------------------------------------
            """
        )
    }
}
