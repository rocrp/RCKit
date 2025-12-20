import RCKit
import SwiftUI

@main
struct RCKitDemoApp: App {
  init() {
    #if canImport(NSLoggerSwift)
      NSLoggerSupport.start()
      RCKit.log.info("NSLogger available: true")
    #else
      RCKit.log.info("NSLogger available: false")
    #endif
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
