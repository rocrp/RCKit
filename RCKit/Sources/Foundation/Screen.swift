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
  #if os(iOS) || os(tvOS) || os(visionOS)
    @MainActor public static func scale(for screen: UIScreen) -> CGFloat {
      screen.scale
    }

    @MainActor public static func scale(for traitCollection: UITraitCollection) -> CGFloat {
      traitCollection.displayScale
    }
  #elseif os(macOS)
    @MainActor public static var scale: CGFloat {
      NSScreen.main?.backingScaleFactor ?? 1
    }
  #elseif os(watchOS)
    public static var scale: CGFloat {
      WKInterfaceDevice.current().screenScale
    }
  #else
    public static var scale: CGFloat {
      preconditionFailure("Screen.scale unsupported platform")
    }
  #endif
}
