# RCKit

RoCry's personal Swift 6.2 + SwiftUI helpers for iOS/macOS projects. Tuist-first.

## Swift 6.2 Approachable Concurrency

This project uses Swift 6.2's Approachable Concurrency features:
- `SWIFT_APPROACHABLE_CONCURRENCY: YES` - Enables SE-0461 (nonisolated async runs on caller's actor) and SE-0470 (infer isolated conformances)
- **RCKit framework**: `nonisolated` by default (appropriate for libraries)
- **RCKitDemo app**: `MainActor` by default via `SWIFT_DEFAULT_ACTOR_ISOLATION` (SE-0466)

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
