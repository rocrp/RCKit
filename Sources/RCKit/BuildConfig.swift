//
//  BuildConfig.swift
//  Protocols
//
//  Created by RoCry on 2023/11/27.
//

import Foundation
import StoreKit

public struct BuildConfig {
    public enum Channel: String, Sendable {
        case debug
        case testflight
        case appstore
    }

    protocol ChannelProbe: Sendable {
        func isSandboxReceipt() async -> Bool
    }

    actor ChannelResolver {
        private let isDebugBuild: Bool
        private let probe: any ChannelProbe
        private var resolution: Task<Channel, Never>?

        init(isDebugBuild: Bool, probe: any ChannelProbe) {
            self.isDebugBuild = isDebugBuild
            self.probe = probe
        }

        func resolve() async -> Channel {
            if let resolution {
                return await resolution.value
            }

            let resolution = Task { [isDebugBuild, probe] in
                guard !isDebugBuild else {
                    return Channel.debug
                }

                return BuildConfig.resolveChannel(
                    isDebugBuild: false,
                    hasSandboxReceipt: await probe.isSandboxReceipt()
                )
            }
            self.resolution = resolution
            return await resolution.value
        }
    }

    private struct AppTransactionChannelProbe: ChannelProbe {
        func isSandboxReceipt() async -> Bool {
            do {
                switch try await AppTransaction.shared {
                case .verified(let appTransaction):
                    return appTransaction.environment == .sandbox
                case .unverified(_, let error):
                    preconditionFailure("BuildConfig Channel Probe failed verification: \(error)")
                }
            } catch {
                preconditionFailure("BuildConfig Channel Probe failed: \(error)")
            }
        }
    }

    private static let channelResolver = ChannelResolver(
        isDebugBuild: allowDebug,
        probe: AppTransactionChannelProbe()
    )

    // via: https://stackoverflow.com/posts/33177600/revisions
    public static let isDebugging: Bool = {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        precondition(junk == 0, "BuildConfig.isDebugging sysctl failed with code \(junk)")
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }()

    public static func channel() async -> Channel {
        await channelResolver.resolve()
    }

    static func resolveChannel(isDebugBuild: Bool, hasSandboxReceipt: Bool) -> Channel {
        if isDebugBuild {
            return .debug
        }
        return hasSandboxReceipt ? .testflight : .appstore
    }
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
