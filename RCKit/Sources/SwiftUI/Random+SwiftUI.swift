//
//  Random.swift
//
//
//  Created by RoCry on 2024/1/16.
//

import SwiftUI

extension Color {
  public static func random() -> Color {
    random(in: defaultPalette)
  }

  public static func random(in palette: [Color]) -> Color {
    precondition(!palette.isEmpty, "Color palette must not be empty")
    guard let color = palette.randomElement() else {
      preconditionFailure("Color palette must not be empty")
    }
    return color
  }

  private static var defaultPalette: [Color] {
    if #available(iOS 15.0, macOS 12.0, *) {
      return [
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        .purple,
        .pink,
        .white,
        .gray,
        .black,
        .mint,
        .teal,
        .cyan,
        .indigo,
        .brown,
      ]
    }

    return [
      .red,
      .orange,
      .yellow,
      .green,
      .blue,
      .purple,
      .pink,
      .white,
      .gray,
      .black,
    ]
  }
}
