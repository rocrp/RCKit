//
//  MemoryFootprint.swift
//  AppaoCore
//
//  Created by cokile on 2019/12/3.
//  Copyright © 2019 appao. All rights reserved.
//

import Foundation

/// Utility for measuring memory usage in the application
public final class MemoryFootprint {
    /// Errors that can occur when retrieving memory information
    public enum Error: Swift.Error, LocalizedError {
        case mach(String)
        case unknown
        case unsupportedPlatform

        public var errorDescription: String? {
            switch self {
            case .mach(let str): return "Mach error: \(str)"
            case .unknown: return "Unknown memory measurement error"
            case .unsupportedPlatform: return "Memory measurement is unsupported on this platform"
            }
        }
    }

    /// Memory usage information
    public struct MemoryUsage {
        /// Internal memory used (resident memory)
        public let residentMemory: UInt64
        /// Compressed memory
        public let compressed: UInt64
        /// Total memory usage (internal + compressed)
        public let total: UInt64

        /// Format memory usage as a human-readable string (e.g., "10.5 MB")
        public func formattedString(unit: MemoryUnit = .auto) -> String {
            return unit == .auto
                ? total.formattedMemorySize
                : total.formattedMemorySize(unit: unit)
        }
    }

    /// Memory size units
    public enum MemoryUnit {
        case bytes
        case kilobytes
        case megabytes
        case gigabytes
        case auto
    }

    /// Get the current memory usage of the application
    /// - Returns: Result containing memory usage or an error
    public static func getMemoryUsage() -> Result<MemoryUsage, Error> {
        #if os(watchOS)
            return .failure(.unsupportedPlatform)
        #else
            let count = MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size

            var vmInfo = task_vm_info_data_t()
            var vmInfoSize = mach_msg_type_number_t(count)

            let kern: kern_return_t = withUnsafeMutablePointer(to: &vmInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &vmInfoSize)
                }
            }

            if kern == KERN_SUCCESS {
                return .success(
                    MemoryUsage(
                        residentMemory: vmInfo.internal,
                        compressed: vmInfo.compressed,
                        total: vmInfo.internal + vmInfo.compressed
                    )
                )
            } else {
                let error: Error =
                    String(cString: mach_error_string(kern), encoding: .ascii).map { Error.mach($0) }
                    ?? .unknown
                RCKit.log.error("Failed to get memory: \(error.localizedDescription)")
                return .failure(error)
            }
        #endif
    }

    /// Get the current memory usage as a formatted string
    /// - Parameter unit: The unit to format the memory in (default is auto)
    /// - Returns: A formatted string or an error message
    public static func getFormattedMemoryUsage(unit: MemoryUnit = .auto) throws -> String {
        let usage = try getMemoryUsage().get()
        return usage.formattedString(unit: unit)
    }

    /// Log the current memory usage
    public static func logMemoryUsage() throws {
        let usage = try getMemoryUsage().get()
        RCKit.log.info("Memory usage: \(usage.formattedString())")
    }
}

// MARK: - Formatting Extensions

extension UInt64 {
    /// Format bytes as a human-readable string
    var formattedMemorySize: String {
        let bytes = Double(self)

        switch bytes {
        case 0 ..< 1024:
            return String(format: "%.0f bytes", bytes)
        case 1024 ..< (1024 * 1024):
            return String(format: "%.1f KB", bytes / 1024)
        case 1024 ..< (1024 * 1024 * 1024):
            return String(format: "%.1f MB", bytes / (1024 * 1024))
        default:
            return String(format: "%.2f GB", bytes / (1024 * 1024 * 1024))
        }
    }

    /// Format bytes as a string with a specific unit
    func formattedMemorySize(unit: MemoryFootprint.MemoryUnit) -> String {
        let bytes = Double(self)

        switch unit {
        case .bytes:
            return String(format: "%.0f bytes", bytes)
        case .kilobytes:
            return String(format: "%.2f KB", bytes / 1024)
        case .megabytes:
            return String(format: "%.2f MB", bytes / (1024 * 1024))
        case .gigabytes:
            return String(format: "%.2f GB", bytes / (1024 * 1024 * 1024))
        case .auto:
            return formattedMemorySize
        }
    }
}
