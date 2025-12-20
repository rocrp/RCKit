import Foundation

enum UTCDateFormatter {
  private static let formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  static func iso8601String(from date: Date) -> String {
    formatter.string(from: date)
  }
}
