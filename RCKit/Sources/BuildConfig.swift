//
//  BuildConfig.swift
//  Protocols
//
//  Created by RoCry on 2023/11/27.
//

import Foundation

public struct BuildConfig {
  // via: https://stackoverflow.com/posts/33177600/revisions
  public static let isDebugging: Bool = {
    var info = kinfo_proc()
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = MemoryLayout<kinfo_proc>.stride
    let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
    precondition(junk == 0, "BuildConfig.isDebugging sysctl failed with code \(junk)")
    return (info.kp_proc.p_flag & P_TRACED) != 0
  }()

  public static let isDebugOrTestFlight: Bool = {
    #if DEBUG
      return true
    #else

      // this will return true when testflight
      return Foundation.Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    #endif
  }()

  public static let channelName: String = {
    #if DEBUG
      return "debug"
    #else
      if isDebugOrTestFlight {
        return "testflight"
      }

      return "appstore"
    #endif
  }()
}

extension BuildConfig {
  public static var allowDebug: Bool {
    #if DEBUG
      return true
    #else
      return false
    #endif
  }
}

extension BuildConfig {
  public struct Bundle {
    public static let identifier: String = {
      guard let identifier = Foundation.Bundle.main.bundleIdentifier else {
        preconditionFailure("Bundle.identifier missing for Bundle.main")
      }
      return identifier
    }()

    public static let shortVersion: String = {
      return Self.requireInfoForKey("CFBundleShortVersionString")
    }()

    public static let version: String = {
      return Self.requireInfoForKey("CFBundleVersion")
    }()

    public static let displayName: String = {
      return Self.infoForKey("CFBundleDisplayName") ?? bundleName
    }()

    public static let bundleName: String = {
      return Self.requireInfoForKey("CFBundleName")
    }()

    public static func infoForKey<T>(_ key: String) -> T? {
      if let obj = Foundation.Bundle.main.infoDictionary?[key] as? T {
        return obj
      }

      return nil
    }

    private static func requireInfoForKey<T>(_ key: String) -> T {
      guard let value: T = infoForKey(key) else {
        preconditionFailure("Missing Bundle.main info key: \(key)")
      }
      return value
    }
  }
}
