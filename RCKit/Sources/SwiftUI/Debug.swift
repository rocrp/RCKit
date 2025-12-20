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
  public func debugBorder<S>(
    _ content: S = Color.randomBorderColor,
    width: CGFloat? = nil
  ) -> some View where S: ShapeStyle {
    modifier(DebugBorderModifier(style: content, width: width))
  }
}

private struct DebugBorderModifier<S: ShapeStyle>: ViewModifier {
  let style: S
  let width: CGFloat?

  @Environment(\.displayScale) private var displayScale

  func body(content: Content) -> some View {
    #if DEBUG
      let lineWidth = width ?? (1.0 / displayScale)
      content.border(style, width: lineWidth)
    #else
      content
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
