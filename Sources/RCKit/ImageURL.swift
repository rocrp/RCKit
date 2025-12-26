//
//  File.swift
//
//
//  Created by RoCry on 2024/1/18.
//

import Foundation

public enum SizeStrategy {
    case width(Int)
    case height(Int)
    case size(width: Int, height: Int)
}

extension URL {
    private var _host: String? {
        if #available(iOS 16.0, watchOS 9.0, *) {
            return host()
        } else {
            return host
        }
    }
    // https://unsplash.com/documentation#supported-parameters
    public mutating func adjustImageSize(_ size: SizeStrategy) {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            preconditionFailure("Invalid URL for image sizing: \(absoluteString)")
        }

        guard let host = _host else {
            preconditionFailure("URL host missing for image sizing: \(absoluteString)")
        }

        switch host {
        case "images.unsplash.com":
            guard let url = components._adjustUnsplash(size).url else {
                preconditionFailure("Failed to build Unsplash image URL: \(absoluteString)")
            }
            self = url
        default:
            preconditionFailure("Unsupported image host for sizing: \(host)")
        }
    }
}

extension URLComponents {
    fileprivate mutating func _adjustUnsplash(_ size: SizeStrategy) -> Self {
        switch size {
        case .height(let h):
            self["w"] = nil
            self["h"] = "\(h)"
        case .width(let w):
            self["w"] = "\(w)"
            self["h"] = nil
        case .size(let w, let h):
            self["w"] = "\(w)"
            self["h"] = "\(h)"
        }
        // q=80&w=4000&auto=format&fit=crop
        self["q"] = "80"
        self["auto"] = "format"
        self["fit"] = "crop"
        return self
    }
}
