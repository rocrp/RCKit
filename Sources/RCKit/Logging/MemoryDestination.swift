//
//  MemoryDestination.swift
//

import Foundation

public final class MemoryDestination: LogDestination, @unchecked Sendable {
    public struct Entry: Equatable, Sendable {
        public let level: LogLevel
        public let message: String
        public let subsystem: String
        public let category: String
        public let file: String
        public let line: UInt
        public let function: String

        public init(
            level: LogLevel,
            message: String,
            subsystem: String,
            category: String,
            file: String,
            line: UInt,
            function: String
        ) {
            self.level = level
            self.message = message
            self.subsystem = subsystem
            self.category = category
            self.file = file
            self.line = line
            self.function = function
        }
    }

    public let minimumLevel: LogLevel
    public let capacity: Int

    private let lock = NSLock()
    private var storedEntries: [Entry] = []

    public init(capacity: Int = 500, minimumLevel: LogLevel = .debug) {
        precondition(capacity > 0, "MemoryDestination capacity must be greater than zero")
        self.capacity = capacity
        self.minimumLevel = minimumLevel
    }

    public var entries: [Entry] {
        lock.withLock { storedEntries }
    }

    public func send(
        level: LogLevel,
        message: String,
        subsystem: String,
        category: String,
        file: String,
        line: UInt,
        function: String
    ) {
        let entry = Entry(
            level: level,
            message: message,
            subsystem: subsystem,
            category: category,
            file: file,
            line: line,
            function: function
        )

        lock.withLock {
            storedEntries.append(entry)
            if storedEntries.count > capacity {
                storedEntries.removeFirst(storedEntries.count - capacity)
            }
        }
    }
}
