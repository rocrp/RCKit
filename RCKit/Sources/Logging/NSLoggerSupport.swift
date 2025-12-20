//
//  NSLoggerSupport.swift
//

#if canImport(NSLogger)
  import NSLogger

  public enum NSLoggerSupport {
    public static let defaultOptions: UInt32 =
      UInt32(kLoggerOption_BufferLogsUntilConnection)
      | UInt32(kLoggerOption_BrowseBonjour)
      | UInt32(kLoggerOption_BrowseOnlyLocalDomain)

    public static func start(
      options: UInt32 = defaultOptions,
      useBonjourForBuildUser: Bool = true
    ) {
      let logger = LoggerGetDefaultLogger()
      LoggerSetOptions(logger, options)
      if useBonjourForBuildUser {
        LoggerSetupBonjourForBuildUser()
      }
      LoggerStart(logger)
    }
  }
#endif
