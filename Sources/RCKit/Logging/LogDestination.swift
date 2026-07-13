//
//  LogDestination.swift
//

import Foundation

/// Receives structured records that have already passed `Log`'s level gate.
///
/// Destinations must not compare `level` with `minimumLevel` in `send`; `Log` is the sole owner
/// of that policy.
public protocol LogDestination: Sendable {
    var minimumLevel: LogLevel { get }

    func send(
        level: LogLevel,
        message: String,
        subsystem: String,
        category: String,
        file: String,
        line: UInt,
        function: String
    )
}

extension LogDestination {
    public var minimumLevel: LogLevel { .debug }
}
