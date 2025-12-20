//
//  Random.swift
//
//
//  Created by RoCry on 2024/1/16.
//

import SwiftUI

extension Color: Randomable {
  private static var choices: [Self] {
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
    } else {
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

  public static func random(size: Int) -> Color {
    guard let color = choices.randomElement() else {
      preconditionFailure("Color choices array must not be empty")
    }
    return color
  }
}
