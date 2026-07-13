//
//  NSLoggerSupport.swift
//

#if canImport(NSLogger)
    import NSLogger

    public enum NSLoggerSupport {
        public static let defaultOptions: UInt32 =
            UInt32(kLoggerOption_BufferLogsUntilConnection)
            | UInt32(kLoggerOption_BrowseBonjour)
            | UInt32(kLoggerOption_BrowsePeerToPeer)
            | UInt32(kLoggerOption_BrowseOnlyLocalDomain)
            | UInt32(kLoggerOption_CaptureSystemConsole)

        public static let remoteOnlyOptions: UInt32 =
            UInt32(kLoggerOption_BufferLogsUntilConnection)
            | UInt32(kLoggerOption_BrowseBonjour)
            | UInt32(kLoggerOption_BrowsePeerToPeer)
            | UInt32(kLoggerOption_BrowseOnlyLocalDomain)

        public static func start(
            options: UInt32 = defaultOptions,
            useSSL: Bool = false,
            useBonjourForBuildUser: Bool = false,
            minimumLevel: LogLevel = .debug,
        ) -> any LogDestination {
            let logger = LoggerGetDefaultLogger()
            var effectiveOptions = options
            if useSSL {
                effectiveOptions |= UInt32(kLoggerOption_UseSSL)
            } else {
                effectiveOptions &= ~UInt32(kLoggerOption_UseSSL)
            }
            LoggerSetOptions(logger, effectiveOptions)
            if useBonjourForBuildUser {
                LoggerSetupBonjourForBuildUser()
            }
            LoggerStart(logger)

            return NSLoggerDestination(minimumLevel: minimumLevel)
        }
    }
#else
    private struct UnavailableNSLoggerDestination: LogDestination {
        let minimumLevel: LogLevel

        func send(
            level: LogLevel,
            message: String,
            subsystem: String,
            category: String,
            file: String,
            line: UInt,
            function: String
        ) {}
    }

    public enum NSLoggerSupport {
        public static func start(
            options: UInt32 = 0,
            useSSL: Bool = false,
            useBonjourForBuildUser: Bool = false,
            minimumLevel: LogLevel = .debug
        ) -> any LogDestination {
            UnavailableNSLoggerDestination(minimumLevel: minimumLevel)
        }
    }
#endif
