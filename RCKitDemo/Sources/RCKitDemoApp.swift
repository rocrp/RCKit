import RCKit
import SwiftUI

@main
struct RCKitDemoApp: App {
  init() {
    #if os(macOS)
      RCKit.log.info("NSLogger disabled on macOS (no dependency linked)")
    #else
      #if canImport(NSLoggerSwift)
        NSLoggerSupport.start()
        RCKit.log.info("NSLogger available: true")
      #else
        RCKit.log.info("NSLogger available: false")
      #endif
    #endif
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
