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
    public func adjustedImageSize(_ size: SizeStrategy) -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }

        guard _host == "images.unsplash.com" else {
            return nil
        }

        return components._adjustUnsplash(size).url
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
