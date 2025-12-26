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
            | UInt32(kLoggerOption_UseSSL)
            | UInt32(kLoggerOption_CaptureSystemConsole)

        public static let remoteOnlyOptions: UInt32 =
            UInt32(kLoggerOption_BufferLogsUntilConnection)
            | UInt32(kLoggerOption_BrowseBonjour)
            | UInt32(kLoggerOption_BrowsePeerToPeer)
            | UInt32(kLoggerOption_BrowseOnlyLocalDomain)
            | UInt32(kLoggerOption_UseSSL)

        public static func start(
            options: UInt32 = defaultOptions,
            useBonjourForBuildUser: Bool = false,
            minimumLevel: LogLevel = .debug
        ) {
            let logger = LoggerGetDefaultLogger()
            LoggerSetOptions(logger, options)
            if useBonjourForBuildUser {
                LoggerSetupBonjourForBuildUser()
            }
            LoggerStart(logger)

            // Auto-add NSLoggerDestination
            Log.addDestination(NSLoggerDestination(minimumLevel: minimumLevel))
        }
    }
#else
    public enum NSLoggerSupport {
        public static func start(
            options: UInt32 = 0,
            useBonjourForBuildUser: Bool = false,
            minimumLevel: LogLevel = .debug
        ) {
            // No-op when NSLogger is not available
        }
    }
#endif
