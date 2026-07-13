//
//  Log.swift
//

import Foundation
import OSLog

private typealias SystemLogger = Logger

private final class LogBootstrapState: @unchecked Sendable {
    private let lock = NSLock()
    private var bootstrappedDestinations: [any LogDestination]?

    func bootstrap(_ destinations: [any LogDestination]) {
        lock.withLock {
            precondition(
                bootstrappedDestinations == nil,
                "Log.bootstrap(_:) may only be called once"
            )
            bootstrappedDestinations = destinations
        }
    }

    var destinations: [any LogDestination] {
        lock.withLock { bootstrappedDestinations ?? [] }
    }
}

public struct Log: Sendable {
    // MARK: - Static Configuration

    private static let bootstrapState = LogBootstrapState()

    /// Configures the process-wide default Destinations exactly once.
    ///
    /// Call this during app startup. A second call is a programmer error and crashes.
    public static func bootstrap(_ destinations: [any LogDestination]) {
        bootstrapState.bootstrap(destinations)
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
    private let destinationsOverride: [any LogDestination]?

    // MARK: - Initialization

    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "dev.rocry.rckit",
        category: String = "general",
        minimumLevel: LogLevel = defaultMinimumLevel,
        redactionMode: RedactionMode = .common,
        destinations: [any LogDestination]? = nil
    ) {
        self.subsystem = subsystem
        self.category = category
        self.minimumLevel = minimumLevel
        self.redactionMode = redactionMode
        self.destinationsOverride = destinations
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

        let baseMessage = render(message(), metadata: metadata)

        // OSLog - include source location in message
        let fileName = file.split(separator: "/").last.map(String.init) ?? file
        let osLogMessage = "\(baseMessage) (\(fileName):\(line) \(function))"
        osLogger.log(level: level.osLogType, "\(osLogMessage, privacy: .public)")

        // Destinations - receive file/line/function separately
        for destination in destinationsOverride ?? Self.bootstrapState.destinations
        where level >= destination.minimumLevel {
            destination.send(
                level: level,
                message: baseMessage,
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
        metadata: [String: any CustomStringConvertible]?
    ) -> String {
        guard let metadata, !metadata.isEmpty else {
            return message
        }

        let metaString =
            metadata
            .sorted { $0.key < $1.key }
            .map { key, value in
                let renderedValue = shouldRedact(key: key) ? "<redacted>" : String(describing: value)
                return "\(key)=\(renderedValue)"
            }
            .joined(separator: " ")
        return "\(message) [\(metaString)]"
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
    public func printDebugInfo() async {
        let channel = await BuildConfig.channel()
        info(
            """
            ---------------- Debug Info ----------------
            isDebugging: \(BuildConfig.isDebugging)
            channel: \(channel.rawValue)
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
