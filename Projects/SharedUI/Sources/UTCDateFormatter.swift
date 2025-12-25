import Foundation

public enum UTCDateFormatter {
    public static func iso8601String(from date: Date) -> String {
        makeFormatter().string(from: date)
    }

    private static func makeFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}
