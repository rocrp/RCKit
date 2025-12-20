//
//  File.swift
//
//
//  Created by RoCry on 2024/1/16.
//

import Foundation

#if canImport(UIKit)
  import UIKit
#endif

#if canImport(AppKit)
  import AppKit
#endif

#if canImport(WatchKit)
  import WatchKit
#endif

public enum Screen {
  @MainActor public static var scale: CGFloat {
    #if os(iOS) || os(tvOS) || os(visionOS)
      return UIScreen.main.scale
    #elseif os(macOS)
      return NSScreen.main?.backingScaleFactor ?? 1
    #elseif os(watchOS)
      return WKInterfaceDevice.current().screenScale
    #else
      preconditionFailure("Screen.scale unsupported platform")
    #endif
  }
}
