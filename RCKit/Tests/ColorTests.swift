//
//  ColorTests.swift
//
//
//  Created by RoCry on 2024/1/16.
//

import SwiftUI
import XCTest

@testable import RCKit

final class ColorTests: XCTestCase {
    func testInitHexColor() throws {
        try testColorEqual(Color(hex: "#000000"), Color.black)
        try testColorEqual(Color(hex: "000000"), Color.black)
        try testColorEqual(Color(hex: "#00000000"), Color.clear)
        try testColorEqual(Color(hex: "0f0f"), Color(red: 0, green: 1, blue: 0, opacity: 1))
        try testColorEqual(Color(hex: "ff0000"), Color(red: 1, green: 0, blue: 0))
        try testColorEqual(Color(hex: "000000FF"), Color.black)
        try testColorEqual(Color(hex: "0000FF"), Color(red: 0, green: 0, blue: 1))
    }

    func testColorEqual(_ c1: Color, _ c2: Color) throws {
        XCTAssertEqual(c1.hex(), c2.hex())
    }

    func testRGBA() throws {
        XCTAssertEqual(Color(red: 1.0, green: 0, blue: 0).rgb()!.red, 1, accuracy: 0.001)

        let rgb = Color(red: 0.3, green: 0.4, blue: 0.5).rgb()!
        XCTAssertEqual(rgb.red, 0.3, accuracy: 0.001)
        XCTAssertEqual(rgb.green, 0.4, accuracy: 0.001)
        XCTAssertEqual(rgb.blue, 0.5, accuracy: 0.001)

        let rgba = Color(red: 0.3, green: 0.4, blue: 0.5, opacity: 0.9).rgba()!
        XCTAssertEqual(rgba.red, 0.3, accuracy: 0.001)
        XCTAssertEqual(rgba.green, 0.4, accuracy: 0.001)
        XCTAssertEqual(rgba.blue, 0.5, accuracy: 0.001)
        XCTAssertEqual(rgba.opacity, 0.9, accuracy: 0.001)

        let rgba2 = Color.white.rgba()!
        XCTAssertEqual(rgba2.red, 1, accuracy: 0.001)
        XCTAssertEqual(rgba2.green, 1, accuracy: 0.001)
        XCTAssertEqual(rgba2.blue, 1, accuracy: 0.001)
        XCTAssertEqual(rgba2.opacity, 1, accuracy: 0.001)

        let rgba3 = Color.black.rgba()!
        XCTAssertEqual(rgba3.red, 0, accuracy: 0.001)
        XCTAssertEqual(rgba3.green, 0, accuracy: 0.001)
        XCTAssertEqual(rgba3.blue, 0, accuracy: 0.001)
        XCTAssertEqual(rgba3.opacity, 1, accuracy: 0.001)
    }

    func testHex() throws {
        XCTAssertEqual(Color.black.hex(), "#000000")
        XCTAssertEqual(Color.white.hex(ignoreAlphaIfNotTransparent: false), "#ffffffff")
        XCTAssertEqual(Color(red: 1.0, green: 0, blue: 0).hex(), "#ff0000")
        XCTAssertEqual(
            Color(red: 1.0, green: 0, blue: 0).hex(ignoreAlphaIfNotTransparent: false),
            "#ff0000ff"
        )

        XCTAssertEqual(Color(hex: "#000000").hex(), "#000000")
        XCTAssertEqual(Color(hex: "000000").hex(), "#000000")
        XCTAssertEqual(Color(hex: "#00000000").hex(), "#00000000")
        XCTAssertEqual(Color(hex: "0f0f").hex(), "#00ff00")
        XCTAssertEqual(Color(hex: "ff0000").hex(), "#ff0000")
        XCTAssertEqual(Color(hex: "000000FF").hex(), "#000000")
        XCTAssertEqual(Color(hex: "0000FF").hex(), "#0000ff")
    }
}
