//
//  NSLoggerDestination.swift
//

#if canImport(NSLogger)
    import NSLogger

    extension LogLevel {
        var nsloggerLevel: Logger.Level {
            switch self {
            case .debug: .noise
            case .info: .important
            case .notice: .info
            case .warning: .warning
            case .error: .error
            case .fault: .error
            }
        }
    }

    public struct NSLoggerDestination: LogDestination {
        public let minimumLevel: LogLevel

        public init(minimumLevel: LogLevel = .debug) {
            self.minimumLevel = minimumLevel
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

            let logger = LoggerGetDefaultLogger()
            let safeLine = min(line, UInt(Int32.max))
            let lineNumber = Int32(safeLine)
            let domain = "\(subsystem):\(category)"

            file.withCString { fileCString in
                function.withCString { functionCString in
                    LogMessageRawToF(
                        logger,
                        fileCString,
                        lineNumber,
                        functionCString,
                        domain,
                        Int32(level.nsloggerLevel.rawValue),
                        message
                    )
                }
            }
        }
    }
#endif
