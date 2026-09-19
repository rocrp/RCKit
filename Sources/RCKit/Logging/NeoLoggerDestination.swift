//
//  NeoLoggerDestination.swift
//

import NeoLogger

extension LogLevel {
    var neoLoggerLevel: Level {
        switch self {
        case .debug: .noise
        case .info: .important
        case .notice: .info
        case .warning: .warning
        case .error: .error
        case .fault: .error
        }
    }
}

/// Streams records to an NSLogger-protocol viewer over the network.
///
/// Pass this to `Log.bootstrap(_:)`. Constructing it is the whole setup — there is
/// no separate start call, and the client buffers until a viewer connects.
public struct NeoLoggerDestination: LogDestination {
    public let minimumLevel: LogLevel
    private let client: NeoLogger

    /// - Parameter client: defaults to the shared client, which browses Bonjour for
    ///   a viewer. Pass your own `NeoLogger(configuration:)` to reach a fixed host.
    public init(minimumLevel: LogLevel = .debug, client: NeoLogger = .shared) {
        self.minimumLevel = minimumLevel
        self.client = client
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
        client.log(
            Domain(rawValue: "\(subsystem):\(category)"),
            level.neoLoggerLevel,
            message,
            file: file,
            line: Int(min(line, UInt(Int.max))),
            function: function
        )
    }
}
