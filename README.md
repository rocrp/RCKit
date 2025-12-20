# RCKit

Swift 6 + SwiftUI helpers. Tuist-first. UTC timestamps.

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

## Format
Requires `swift-format` on PATH.

```bash
./Scripts/format.sh
./Scripts/lint.sh
```

## Notes
- JSONCoding: ISO8601 UTC, fractional seconds
- Logging: OSLog + NSLogger (optional)
- Fail-fast: invalid inputs preconditionFailure

## NSLogger (optional)
- Add NSLogger framework to app target (CocoaPods/Carthage/manual).
- Demo auto-starts when module available (`RCKitDemoApp`).
- Manual start: `NSLoggerSupport.start()`; disable sink via `RCKitLog.makeLogger(enableNSLogger: false)`.
