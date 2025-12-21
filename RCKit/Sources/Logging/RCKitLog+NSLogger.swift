//
//  RCKitLog+NSLogger.swift
//

#if canImport(NSLoggerSwift)
    import NSLoggerSwift

    extension RCKitLog.Level {
        var nsloggerLevel: NSLoggerSwift.Logger.Level {
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
        private let logger: NSLoggerSwift.Logger
        private let domain: NSLoggerSwift.Logger.Domain

        init(domain: String) {
            self.logger = NSLoggerSwift.Logger.shared
            self.domain = NSLoggerSwift.Logger.Domain(rawValue: domain)
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
