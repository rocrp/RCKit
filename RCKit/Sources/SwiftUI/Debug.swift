//
//  Debug.swift
//
//
//  Created by RoCry on 2024/1/16.
//

import SwiftUI

extension Color {
  public static var randomBorderColor: Self {
    let colors: [Self] = [
      .red,
      .orange,
      .yellow,
      .green,
      .blue,
      .purple,
      .pink,
    ]
    guard let color = colors.randomElement() else {
      preconditionFailure("Border color choices array must not be empty")
    }
    return color
  }
}

extension View {
  @MainActor @inlinable public func debugBorder<S>(
    _ content: S = Color.randomBorderColor,
    width: CGFloat = 1.0 / Screen.scale
  ) -> some View where S: ShapeStyle {
    #if DEBUG
      border(content, width: width)
    #else
      self
    #endif
  }
}

@available(iOS 15.0, macOS 12.0, *) #Preview {
  VStack {
    Rectangle().frame(width: 100, height: 50)
    Rectangle().frame(width: 100, height: 50)
      .debugBorder()
    Rectangle().frame(width: 100, height: 50)
      .debugBorder()
    Rectangle().frame(width: 100, height: 50)
      .debugBorder()
  }.foregroundStyle(.gray)
}
