//
//  RCKitLog.swift
//

import Foundation
import OSLog

private typealias SystemLogger = Logger

protocol LogSink {
  func send(
    level: RCKitLog.Level,
    message: String,
    file: String,
    line: UInt,
    function: String
  )
}

public struct RCKitLog: @unchecked Sendable {
  public enum RedactionMode: Sendable {
    case none
    case common
    case keys(Set<String>)
  }

  public enum Level: Int, Comparable, Sendable {
    case debug = 0
    case info
    case notice
    case warning
    case error
    case fault

    public static func < (lhs: Self, rhs: Self) -> Bool {
      lhs.rawValue < rhs.rawValue
    }

    var osLogType: OSLogType {
      switch self {
      case .debug: return .debug
      case .info: return .info
      case .notice: return .default
      case .warning: return .error
      case .error: return .error
      case .fault: return .fault
      }
    }
  }

  public static let defaultMinimumLevel: Level = {
    #if DEBUG
      return BuildConfig.isDebugging ? .debug : .info
    #else
      return .notice
    #endif
  }()

  public static func makeLogger(
    subsystem: String = "dev.rocry.rckit",
    category: String = "general",
    enableNSLogger: Bool = true,
    redactionMode: RedactionMode = .common,
    minimumLevel: Level = defaultMinimumLevel
  ) -> RCKitLog {
    RCKitLog(
      osLogger: SystemLogger(subsystem: subsystem, category: category),
      minimumLevel: minimumLevel,
      subsystem: subsystem,
      category: category,
      enableNSLogger: enableNSLogger,
      redactionMode: redactionMode
    )
  }

  private let osLogger: SystemLogger
  private let minimumLevel: Level
  private let subsystem: String
  private let category: String
  private let sink: LogSink?
  private let redactionMode: RedactionMode

  private init(
    osLogger: SystemLogger,
    minimumLevel: Level,
    subsystem: String,
    category: String,
    enableNSLogger: Bool,
    redactionMode: RedactionMode
  ) {
    self.osLogger = osLogger
    self.minimumLevel = minimumLevel
    self.subsystem = subsystem
    self.category = category
    self.redactionMode = redactionMode
    self.sink = RCKitLog.makeNSLoggerSink(subsystem: subsystem, enableNSLogger: enableNSLogger)

    log(.info, "Logger initialized", metadata: ["subsystem": subsystem, "category": category])
  }

  @inline(__always)
  private func shouldLog(_ level: Level) -> Bool {
    level >= minimumLevel
  }

  public func log(
    _ level: Level,
    _ message: @autoclosure () -> String,
    metadata: [String: CustomStringConvertible]? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    guard shouldLog(level) else { return }

    let composed = render(
      message(),
      metadata: metadata,
      file: file,
      function: function,
      line: line
    )

    osLogger.log(level: level.osLogType, "\(composed, privacy: .public)")
    sink?.send(level: level, message: composed, file: file, line: line, function: function)
  }

  private func render(
    _ message: String,
    metadata: [String: CustomStringConvertible]?,
    file: String,
    function: String,
    line: UInt
  ) -> String {
    var parts: [String] = [message]

    if let metadata, !metadata.isEmpty {
      let metaString = renderMetadata(metadata)
      parts.append("[\(metaString)]")
    }

    parts.append("(\(file)#\(line) \(function))")

    return parts.joined(separator: " ")
  }

  private func renderMetadata(_ metadata: [String: CustomStringConvertible]) -> String {
    metadata
      .sorted { $0.key < $1.key }
      .map { key, value in
        let renderedValue = shouldRedact(key: key) ? "<redacted>" : String(describing: value)
        return "\(key)=\(renderedValue)"
      }
      .joined(separator: " ")
  }

  private func shouldRedact(key: String) -> Bool {
    switch redactionMode {
    case .none:
      return false
    case .keys(let keys):
      return keys.contains(normalizeKey(key))
    case .common:
      let normalized = normalizeKey(key)
      return RCKitLog.commonRedactionSubstrings.contains { normalized.contains($0) }
    }
  }

  private func normalizeKey(_ key: String) -> String {
    key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }

  private static let commonRedactionSubstrings: [String] = [
    "password",
    "passwd",
    "secret",
    "token",
    "apikey",
    "api_key",
    "authorization",
    "jwt",
    "session",
    "cookie",
    "credential",
    "bearer",
  ]

  public func debug(
    _ message: @autoclosure () -> String,
    metadata: [String: CustomStringConvertible]? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    log(.debug, message(), metadata: metadata, file: file, function: function, line: line)
  }

  public func info(
    _ message: @autoclosure () -> String,
    metadata: [String: CustomStringConvertible]? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    log(.info, message(), metadata: metadata, file: file, function: function, line: line)
  }

  public func notice(
    _ message: @autoclosure () -> String,
    metadata: [String: CustomStringConvertible]? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    log(.notice, message(), metadata: metadata, file: file, function: function, line: line)
  }

  public func warning(
    _ message: @autoclosure () -> String,
    metadata: [String: CustomStringConvertible]? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    log(.warning, message(), metadata: metadata, file: file, function: function, line: line)
  }

  public func error(
    _ message: @autoclosure () -> String,
    metadata: [String: CustomStringConvertible]? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    log(.error, message(), metadata: metadata, file: file, function: function, line: line)
  }

  public func fault(
    _ message: @autoclosure () -> String,
    metadata: [String: CustomStringConvertible]? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    log(.fault, message(), metadata: metadata, file: file, function: function, line: line)
  }

  private static func makeNSLoggerSink(
    subsystem: String,
    enableNSLogger: Bool
  ) -> LogSink? {
    #if os(macOS)
      return nil
    #else
      #if canImport(NSLoggerSwift)
        guard enableNSLogger else { return nil }
        return NSLoggerSink(domain: subsystem)
      #else
        return nil
      #endif
    #endif
  }
}

extension RCKitLog {
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
