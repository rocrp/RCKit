import Foundation

/// ISO 8601 UTC parser/formatter. Always outputs UTC; accepts fractional/non-fractional seconds.
/// Creates formatters per call to avoid shared mutable state under Swift 6 concurrency.
public enum ISO8601UTC {
    public static func string(from date: Date, includeFractionalSeconds: Bool = true) -> String {
        makeFormatter(includeFractionalSeconds: includeFractionalSeconds).string(from: date)
    }

    public static func string(from date: Date?) -> String? {
        guard let date else {
            return nil
        }
        return string(from: date)
    }

    public static func date(from string: String) -> Date? {
        for formatter in makeParsers() {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }

    public static func date(from string: String?) -> Date? {
        guard let string else {
            return nil
        }
        return date(from: string)
    }

    private static func makeParsers() -> [ISO8601DateFormatter] {
        [
            makeFormatter(includeFractionalSeconds: true),
            makeFormatter(includeFractionalSeconds: false),
        ]
    }

    private static func makeFormatter(includeFractionalSeconds: Bool) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions =
            includeFractionalSeconds
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
}
