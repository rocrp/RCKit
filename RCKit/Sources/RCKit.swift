//
//  RCKit.swift
//

import Foundation

public enum RCKit {
  public static let log: RCKitLog = RCKitLog.makeLogger()
  public static let json: JSONCoding.Type = JSONCoding.self
}
