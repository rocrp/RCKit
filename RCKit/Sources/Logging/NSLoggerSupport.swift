//
//  NSLoggerSupport.swift
//

#if canImport(NSLoggerSwift)
    import NSLoggerSwift

    public enum NSLoggerSupport {
        public static let defaultOptions: UInt32 =
            UInt32(kLoggerOption_BufferLogsUntilConnection)
            | UInt32(kLoggerOption_BrowseBonjour)
            | UInt32(kLoggerOption_BrowsePeerToPeer)
            | UInt32(kLoggerOption_BrowseOnlyLocalDomain)
            | UInt32(kLoggerOption_UseSSL)
            | UInt32(kLoggerOption_CaptureSystemConsole)

        public static func start(
            options: UInt32 = defaultOptions,
            useBonjourForBuildUser: Bool = false
        ) {
            let logger = LoggerGetDefaultLogger()
            LoggerSetOptions(logger, options)
            if useBonjourForBuildUser {
                LoggerSetupBonjourForBuildUser()
            }
            LoggerStart(logger)
        }
    }
#else
    public enum NSLoggerSupport {
        public static func start(
            options: UInt32 = 0,
            useBonjourForBuildUser: Bool = false
        ) {
            preconditionFailure(
                "NSLoggerSwift unavailable. Add NSLoggerSwift.xcframework and ensure it is linked for iOS targets."
            )
        }
    }
#endif
