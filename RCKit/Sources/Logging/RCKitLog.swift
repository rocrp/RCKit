//
//  RCKitLog.swift
//

import Foundation
import Logging

public enum RCKitLog {
  public static let defaultMinimumLevel: Logger.Level = {
    #if DEBUG
      return BuildConfig.isDebugging ? .debug : .info
    #else
      return .notice
    #endif
  }()

  private static let lock = NSLock()
  private static var didBootstrap = false
  private static var bootstrappedLevel: Logger.Level?

  public static func bootstrap(minimumLevel: Logger.Level = defaultMinimumLevel) {
    lock.lock()
    defer { lock.unlock() }

    if didBootstrap {
      if let bootstrappedLevel, bootstrappedLevel != minimumLevel {
        preconditionFailure(
          "RCKitLog.bootstrap called more than once with different minimumLevel. Existing: \(bootstrappedLevel), new: \(minimumLevel)"
        )
      }
      return
    }

    LoggingSystem.bootstrap { label in
      var handler = UTCLogHandler(label: label)
      handler.logLevel = minimumLevel
      return handler
    }

    didBootstrap = true
    bootstrappedLevel = minimumLevel
  }

  public static func make(
    label: String,
    subsystem: String? = nil,
    category: String? = nil,
    minimumLevel: Logger.Level = defaultMinimumLevel,
    metadata: Logger.Metadata = [:]
  ) -> Logger {
    bootstrap(minimumLevel: minimumLevel)

    var logger = Logger(label: label)
    logger.logLevel = minimumLevel

    var merged = metadata
    if let subsystem {
      merged["subsystem"] = .string(subsystem)
    }
    if let category {
      merged["category"] = .string(category)
    }
    if !merged.isEmpty {
      logger.metadata.merge(merged, uniquingKeysWith: { _, new in new })
    }

    return logger
  }

  public static let logger: Logger = make(
    label: "dev.rocry.rckit",
    subsystem: "dev.rocry.rckit",
    category: "general"
  )
}

public extension Logger {
  func printDebugInfo() {
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

struct UTCLogHandler: LogHandler {
  private let label: String

  var logLevel: Logger.Level = .info
  var metadata: Logger.Metadata = [:]
  var metadataProvider: Logger.MetadataProvider?

  init(label: String) {
    self.label = label
  }

  func log(
    level: Logger.Level,
    message: Logger.Message,
    metadata: Logger.Metadata?,
    source: String,
    file: String,
    function: String,
    line: UInt
  ) {
    let timestamp = UTCISO8601Timestamp.string(from: Date())
    let levelString = level.rawValue.uppercased()
    let combinedMetadata = Self.prepareMetadata(
      base: self.metadata,
      provider: metadataProvider,
      explicit: metadata
    )
    let metadataString = combinedMetadata
      .sorted(by: { $0.key < $1.key })
      .map { "\($0.key)=\($0.value)" }
      .joined(separator: " ")

    let location = "\(file)#\(line) \(function)"
    let metadataSuffix = metadataString.isEmpty ? "" : " [\(metadataString)]"
    let logLine = "\(timestamp) \(levelString) \(label)\(metadataSuffix) \(message) (\(location))"

    print(logLine)
  }

  subscript(metadataKey key: String) -> Logger.Metadata.Value? {
    get { metadata[key] }
    set { metadata[key] = newValue }
  }

  private static func prepareMetadata(
    base: Logger.Metadata,
    provider: Logger.MetadataProvider?,
    explicit: Logger.Metadata?
  ) -> Logger.Metadata {
    var merged = base

    let provided = provider?.get() ?? [:]
    if !provided.isEmpty {
      merged.merge(provided, uniquingKeysWith: { _, provided in provided })
    }

    if let explicit, !explicit.isEmpty {
      merged.merge(explicit, uniquingKeysWith: { _, explicit in explicit })
    }

    return merged
  }
}

private enum UTCISO8601Timestamp {
  private static let lock = NSLock()
  private static let formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  static func string(from date: Date) -> String {
    lock.lock()
    defer { lock.unlock() }
    return formatter.string(from: date)
  }
}
