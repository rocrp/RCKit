import RCKit
import SwiftUI

@main
struct RCKitDemoApp: App {
  init() {
    RCKitLog.bootstrap()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
