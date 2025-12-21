//
//  File.swift
//
//
//  Created by RoCry on 2024/1/16.
//

import Foundation

extension TimeInterval {
    // returns 15s, 1h, 3d, 1mo, 2y
    public var shortString: String {
        let isNegative = self < 0
        let interval = isNegative ? -self : self
        let sign = isNegative ? "-" : ""

        switch interval {
        case 0 ..< 60:
            return "\(sign)\(Int(interval))s"
        case 60 ..< 3600:
            return "\(sign)\(Int(interval / 60))m"
        case 3600 ..< 3600 * 24:
            return "\(sign)\(Int(interval / 3600))h"
        case 3600 * 24 ..< 3600 * 24 * 30:
            return "\(sign)\(Int(interval / 86400))d"
        case 3600 * 24 * 30 ..< 3600 * 24 * 365:
            return "\(sign)\(Int(interval / 2_592_000))mo"
        default:
            return "\(sign)\(Int(interval / 31_536_000))y"
        }
    }
}
