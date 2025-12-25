//
//  RCKitLog+NSLogger.swift
//

#if canImport(NSLoggerSwift)
    import NSLoggerSwift

    extension RCKitLog.Level {
        var nsloggerLevel: Int32 {
            switch self {
            case .debug: return 3
            case .info: return 2
            case .notice: return 1
            case .warning: return 1
            case .error: return 0
            case .fault: return 0
            }
        }
    }

    struct NSLoggerSink: LogSink {
        private let domain: String

        init(domain: String) {
            self.domain = domain
        }

        func send(
            level: RCKitLog.Level,
            message: String,
            file: String,
            line: UInt,
            function: String
        ) {
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
