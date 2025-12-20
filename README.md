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

Bootstrap once (App init):

```swift
RCKitLog.bootstrap()
```

## Notes
- JSONCoding: ISO8601 UTC, fractional seconds
- Logging: apple/swift-log, UTC timestamp
- Fail-fast: invalid inputs preconditionFailure
