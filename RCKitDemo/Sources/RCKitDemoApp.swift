import RCKit
import SwiftUI

@main
struct RCKitDemoApp: App {
  init() {
    #if canImport(NSLogger)
      NSLoggerSupport.start()
    #endif
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
