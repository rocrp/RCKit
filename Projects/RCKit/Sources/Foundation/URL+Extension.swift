//
//  URL+Extension.swift
//
//
//  Created by RoCry on 2024/1/18.
//

import Foundation

extension URL {
    public subscript(key: String) -> String? {
        get {
            guard let comps = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
                return nil
            }

            return comps[key]
        }
        set {
            guard var comps = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
                preconditionFailure("Invalid URL for query update: \(absoluteString)")
            }

            comps[key] = newValue
            guard let url = comps.url else {
                preconditionFailure("Failed to build URL from components: \(comps)")
            }
            self = url
        }
    }

    public func queryString(sort: Bool = false) -> String {
        guard let comps = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            preconditionFailure("Invalid URL for query string: \(absoluteString)")
        }

        return comps.queryString(sort: sort)
    }
}

extension URLComponents {
    public subscript(key: String) -> String? {
        get {
            guard let items = queryItems else {
                return nil
            }

            for i in items {
                if i.name == key {
                    return i.value
                }
            }

            return nil
        }
        set {
            if queryItems == nil {
                queryItems = []
            }

            queryItems?.removeAll(where: { $0.name == key })

            if let value = newValue {
                queryItems?.append(URLQueryItem(name: key, value: value))
            } else {
                if queryItems?.isEmpty == true {
                    queryItems = nil
                }
            }
        }
    }

    public mutating func replaceQueryItems(with parameters: [String: String]) {
        queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
    }

    public mutating func updateIfNotExists(key: String, value: String) {
        if self[key] == nil {
            self[key] = value
        }
    }

    // returns the query string: "", "a=b", "a=b&c=d"
    // will remove empty values: "c=d" instead of "a=&c=d"
    public func queryString(sort: Bool = false) -> String {
        guard let items = queryItems else {
            return ""
        }

        var kvs = items.compactMap { item -> String? in
            guard let value = item.value else {
                return nil
            }

            return "\(item.name)=\(value)"
        }

        if sort {
            kvs.sort()
        }

        return kvs.joined(separator: "&")
    }
}
