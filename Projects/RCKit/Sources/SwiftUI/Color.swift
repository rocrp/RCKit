//
//  File.swift
//
//
//  Created by RoCry on 2024/1/16.
//

import SwiftUI

#if os(macOS)
    import AppKit
    typealias PlatformColor = NSColor
#else
    import UIKit
    typealias PlatformColor = UIColor
#endif

public protocol HexLike {
    var hex: String { get }
}

extension String: HexLike {
    public var hex: String { self }
}

extension Int: HexLike {
    public var hex: String {
        precondition(self >= 0, "Hex color value must be non-negative")
        if self <= 0xFFFFFF {
            return String(format: "%06x", self)
        }
        if self <= 0xFFFF_FFFF {
            return String(format: "%08x", self)
        }
        preconditionFailure("Hex color value out of range: \(self)")
    }
}

extension Color {
    // supports RGB, RGBA, RRGGBB, RRGGBBAA (with or without #)
    public init(hex: HexLike) {
        let string = hex.hex.trimmingCharacters(in: .whitespacesAndNewlines)
        precondition(!string.isEmpty, "Hex color string must not be empty")
        let hexString = string.hasPrefix("#") ? String(string.dropFirst()) : string
        let normalized = hexString.lowercased()

        precondition(
            normalized.allSatisfy { "0123456789abcdef".contains($0) },
            "Invalid hex color string: \(string)"
        )

        guard let i = UInt64(normalized, radix: 16) else {
            preconditionFailure("Invalid hex color string: \(string)")
        }

        let r: UInt64
        let g: UInt64
        let b: UInt64
        let a: UInt64
        switch normalized.count {
        case 3:
            (r, g, b, a) = (
                (i >> 8) * 17,
                (i >> 4 & 0xF) * 17,
                (i & 0xF) * 17,
                255
            )
        case 4:
            (r, g, b, a) = (
                (i >> 12) * 17,
                (i >> 8 & 0xF) * 17,
                (i >> 4 & 0xF) * 17,
                (i & 0xF) * 17
            )
        case 6:
            (r, g, b, a) = (
                i >> 16,
                i >> 8 & 0xFF,
                i & 0xFF,
                255
            )
        case 8:
            (r, g, b, a) = (
                i >> 24,
                i >> 16 & 0xFF,
                i >> 8 & 0xFF,
                i & 0xFF
            )
        default:
            preconditionFailure("Hex color string must be 3, 4, 6, or 8 digits: \(string)")
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    public func hex(ignoreAlphaIfNotTransparent: Bool = true) -> String {
        guard let rgba = rgba() else {
            preconditionFailure("Unable to extract RGBA components from Color")
        }
        let r = Int(round(rgba.red * 255))
        let g = Int(round(rgba.green * 255))
        let b = Int(round(rgba.blue * 255))
        let a = Int(round(rgba.opacity * 255))
        if ignoreAlphaIfNotTransparent && a == 255 {
            return String(format: "#%02x%02x%02x", r, g, b)
        }
        return String(format: "#%02x%02x%02x%02x", r, g, b, a)
    }

    public func rgba() -> (red: Double, green: Double, blue: Double, opacity: Double)? {
        #if os(macOS)
            guard let rgbColor = PlatformColor(self).usingColorSpace(.deviceRGB) else {
                return nil
            }
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return (Double(red), Double(green), Double(blue), Double(alpha))
        #else
            let platformColor = PlatformColor(self)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            guard platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
                return nil
            }
            return (Double(red), Double(green), Double(blue), Double(alpha))
        #endif
    }

    public func rgb() -> (red: Double, green: Double, blue: Double)? {
        guard let rgba = rgba() else { return nil }
        return (rgba.red, rgba.green, rgba.blue)
    }
}
