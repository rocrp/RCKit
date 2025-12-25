//
//  LogLevel.swift
//

import OSLog

public enum LogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info
    case notice
    case warning
    case error
    case fault

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var osLogType: OSLogType {
        switch self {
        case .debug: .debug
        case .info: .info
        case .notice: .default
        case .warning: .error
        case .error: .error
        case .fault: .fault
        }
    }

    var symbol: String {
        switch self {
        case .debug: "🔍"
        case .info: "ℹ️"
        case .notice: "📝"
        case .warning: "⚠️"
        case .error: "❌"
        case .fault: "💥"
        }
    }

    var label: String {
        switch self {
        case .debug: "DEBUG"
        case .info: "INFO"
        case .notice: "NOTICE"
        case .warning: "WARN"
        case .error: "ERROR"
        case .fault: "FAULT"
        }
    }
}
