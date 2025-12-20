//
//  JSONCoding.swift
//
//  Created by RoCry on 2025/12/19.
//

import Foundation

public enum JSONCoding {
  public static func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .custom { date, encoder in
      var container = encoder.singleValueContainer()
      try container.encode(UTCISO8601.string(from: date))
    }
    return encoder
  }

  public static func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let value = try container.decode(String.self)
      guard let date = UTCISO8601.date(from: value) else {
        throw DecodingError.dataCorruptedError(
          in: container,
          debugDescription: "Invalid ISO8601 UTC date string: \(value)"
        )
      }
      return date
    }
    return decoder
  }
}

private enum UTCISO8601 {
  private static let formatterWithFractionalSeconds: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()

  static func string(from date: Date) -> String {
    formatterWithFractionalSeconds.string(from: date)
  }

  static func date(from string: String) -> Date? {
    formatterWithFractionalSeconds.date(from: string) ?? formatter.date(from: string)
  }
}
