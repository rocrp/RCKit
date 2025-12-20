# RCKit

RoCry's Personal Swift 6 + SwiftUI helpers for iOS and macOS personal projects. Tuist-first. 

## Targets
- `RCKit` framework
- `RCKitDemo` app (SwiftUI demo)
- `RCKitTests` unit tests

## Tuist use
Dependency:

```swift
.dependencies: [
  .project(target: "RCKit", path: "../RCKit")
]
```

No bootstrap needed. Use `RCKit.log` directly.

## Notes
- Logging: OSLog + NSLoggerSwift (optional)
- Fail-fast: invalid inputs preconditionFailure

## NSLogger (optional)
- Vendored: `Dependencies/NSLoggerSwift.xcframework` (module `NSLoggerSwift`).
- Demo auto-starts and logs availability in `RCKitDemoApp`.
- Info.plist for demo already includes `NSBonjourServices` + `NSLocalNetworkUsageDescription`.
- Manual start: `NSLoggerSupport.start()`; for per-user Bonjour use `useBonjourForBuildUser: true` and set viewer to your `$USER`.
- Disable sink via `RCKitLog.makeLogger(enableNSLogger: false)`.
