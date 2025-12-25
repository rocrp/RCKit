//
//  String.swift
//
//
//  Created by RoCry on 2024/1/18.
//

import Foundation

extension String {
    public func url() -> URL {
        guard let url = URL(string: self) else {
            preconditionFailure("Invalid URL string: \(self)")
        }
        return url
    }

    public func removingCharacters(in set: CharacterSet) -> String {
        return components(separatedBy: set).joined()
    }
}
