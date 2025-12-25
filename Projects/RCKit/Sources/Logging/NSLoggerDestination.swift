//
//  NSLoggerDestination.swift
//

#if canImport(NSLogger)
    import NSLogger

    extension LogLevel {
        var nsloggerLevel: Int32 {
            switch self {
            case .debug: 3
            case .info: 2
            case .notice: 1
            case .warning: 1
            case .error: 0
            case .fault: 0
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
