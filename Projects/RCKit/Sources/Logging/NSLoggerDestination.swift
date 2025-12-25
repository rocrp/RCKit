//
//  NSLoggerDestination.swift
//

#if canImport(NSLogger)
    import NSLogger

    extension LogLevel {
        var nsloggerLevel: Int32 {
            switch self {
            case .debug: Int32(Logger.Level.noise.rawValue)
            case .info: Int32(Logger.Level.important.rawValue)
            case .notice: Int32(Logger.Level.info.rawValue)
            case .warning: Int32(Logger.Level.warning.rawValue)
            case .error: Int32(Logger.Level.error.rawValue)
            case .fault: Int32(Logger.Level.error.rawValue)
            }
        }
    }

    public struct NSLoggerDestination: LogDestination {
        public let minimumLevel: LogLevel
        private let domain: String

        public init(domain: String, minimumLevel: LogLevel = .debug) {
            self.domain = domain
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

            file.withCString { fileCString in
                function.withCString { functionCString in
                    LogMessageRawToF(
                        logger,
                        fileCString,
                        lineNumber,
                        functionCString,
                        domain,
                        level.nsloggerLevel,
                        message
                    )
                }
            }
        }
    }
#endif
