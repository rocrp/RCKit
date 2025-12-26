//
//  LogDestination.swift
//

import Foundation

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
