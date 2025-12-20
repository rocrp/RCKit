//
//  File.swift
//
//
//  Created by RoCry on 2024/1/16.
//

import Foundation

extension Date {
  // returns 1s, 3d, 2h, -2m (means 2 minutes after now)
  public func relativeShortString(comparing date: Date = Date()) -> String {
    let diff = date.timeIntervalSince(self)
    return diff.shortString
  }
}
