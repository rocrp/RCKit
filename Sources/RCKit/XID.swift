//
//  XID.swift
//  AppaoCore
//
//  Created by cokile on 2019/11/28.
//  Copyright © 2019 appao. All rights reserved.
//
//

// Translated from: https://github.com/rs/xid/blob/master/id.go

import Foundation

/// XID is a globally unique identifier generator
/// Inspired by: https://github.com/rs/xid
public struct XID {
    /// Generate a new XID
    /// - Parameter date: Optional date to use (defaults to current date)
    /// - Returns: String representation of the XID
    /// - Throws: XID.Error if date cannot be processed
    public static func generate(date: Date = Date()) throws -> String {
        return _encode(bytes: try _generateBytes(date: date))
    }
}

extension XID {
    public enum Error: Swift.Error {
        case nanDate
        case infiniteDate
        case dateOverflow
    }
}

extension XID {
    fileprivate static let encoding: [Character] = Array("0123456789abcdefghijklmnopqrstuv")

    fileprivate static let machineID = UUID().uuidString.sha256
    fileprivate static let pid = ProcessInfo.processInfo.processIdentifier
    fileprivate static let counterBox = CounterBox()

    fileprivate static let bytifiedMachineID = [UInt8](machineID.utf8)
    fileprivate static func _timestamp(for date: Date) throws -> UInt32 {
        if date.timeIntervalSince1970.isNaN {
            throw Error.nanDate
        } else if date.timeIntervalSince1970.isInfinite {
            throw Error.infiniteDate
        } else if date.timeIntervalSince1970 > TimeInterval(UInt32.max) {
            throw Error.dateOverflow
        } else {
            return UInt32(date.timeIntervalSince1970)
        }
    }

    static func encode(
        timestamp: UInt32,
        machineID: [UInt8],
        processID: UInt16,
        counter: UInt32
    ) -> String {
        _encode(
            bytes: _makeBytes(
                timestamp: timestamp,
                machineID: machineID,
                processID: processID,
                counter: counter
            )
        )
    }

    fileprivate static func _generateBytes(date: Date) throws -> [UInt8] {
        _makeBytes(
            timestamp: try _timestamp(for: date),
            machineID: Array(bytifiedMachineID.prefix(3)),
            processID: UInt16(truncatingIfNeeded: pid),
            counter: counterBox.next()
        )
    }

    fileprivate static func _makeBytes(
        timestamp: UInt32,
        machineID: [UInt8],
        processID: UInt16,
        counter: UInt32
    ) -> [UInt8] {
        precondition(machineID.count == 3, "XID machine ID must contain exactly 3 bytes")

        return timestamp.bytes + machineID + processID.bytes + counter.bytes.suffix(3)
    }

    fileprivate static func _encode(bytes: [UInt8]) -> String {
        var result = [Character](repeating: " ", count: 20)

        result[19] = encoding[Int((bytes[11] << 4) & 0x1F)]
        result[18] = encoding[Int((bytes[11] >> 1) & 0x1F)]
        result[17] = encoding[Int((bytes[11] >> 6) & 0x1F | (bytes[10] << 2) & 0x1F)]
        result[16] = encoding[Int(bytes[10] >> 3)]
        result[15] = encoding[Int(bytes[9] & 0x1F)]
        result[14] = encoding[Int((bytes[9] >> 5) | (bytes[8] << 3) & 0x1F)]
        result[13] = encoding[Int((bytes[8] >> 2) & 0x1F)]
        result[12] = encoding[Int(bytes[8] >> 7 | (bytes[7] << 1) & 0x1F)]
        result[11] = encoding[Int((bytes[7] >> 4) & 0x1F | (bytes[6] << 4) & 0x1F)]
        result[10] = encoding[Int((bytes[6] >> 1) & 0x1F)]
        result[9] = encoding[Int((bytes[6] >> 6) & 0x1F | (bytes[5] << 2) & 0x1F)]
        result[8] = encoding[Int(bytes[5] >> 3)]
        result[7] = encoding[Int(bytes[4] & 0x1F)]
        result[6] = encoding[Int(bytes[4] >> 5 | (bytes[3] << 3) & 0x1F)]
        result[5] = encoding[Int((bytes[3] >> 2) & 0x1F)]
        result[4] = encoding[Int(bytes[3] >> 7 | (bytes[2] << 1) & 0x1F)]
        result[3] = encoding[Int((bytes[2] >> 4) & 0x1F | (bytes[1] << 4) & 0x1F)]
        result[2] = encoding[Int((bytes[1] >> 1) & 0x1F)]
        result[1] = encoding[Int((bytes[1] >> 6) & 0x1F | (bytes[0] << 2) & 0x1F)]
        result[0] = encoding[Int(bytes[0] >> 3)]

        return String(result)
    }
}

// MARK: - Helper Extensions
extension FixedWidthInteger {
    var bytes: [UInt8] {
        var value = self.bigEndian
        return withUnsafeBytes(of: &value) { Array($0) }
    }
}

private final class CounterBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value: UInt32 = UInt32.random(in: 0...UInt32.max)

    func next() -> UInt32 {
        lock.lock()
        defer { lock.unlock() }
        value = value &+ 1
        return value
    }
}
