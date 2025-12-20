//
//  RCKitLog+NSLogger.swift
//

#if canImport(NSLogger)
  import NSLogger

  extension RCKitLog.Level {
    var nsloggerLevel: NSLogger.Logger.Level {
      switch self {
      case .debug: return .debug
      case .info: return .info
      case .notice: return .important
      case .warning: return .warning
      case .error: return .error
      case .fault: return .error
      }
    }
  }

  struct NSLoggerSink: LogSink {
    private let logger: NSLogger.Logger
    private let domain: NSLogger.Logger.Domain

    init(domain: String) {
      self.logger = NSLogger.Logger.shared
      self.domain = NSLogger.Logger.Domain(rawValue: domain)
    }

    func send(
      level: RCKitLog.Level,
      message: String,
      file: String,
      line: UInt,
      function: String
    ) {
      logger.log(domain, level.nsloggerLevel, message, file, Int(line), function)
    }
  }
#endif
