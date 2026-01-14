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

## Logging

```swift
import RCKit

// Create a logger alias (recommended pattern)
private let logger = Log.default

logger.info("message")
logger.debug("debug info")
logger.error("failed", metadata: ["code": 500])

// Or create custom logger with specific category
private let networkLogger = Log(category: "network")
networkLogger.info("request sent")
```

Output format: `message (File.swift:42 functionName())`

## NSLogger (optional)

- Local SPM package: `../NSLogger`
- Supports iOS and macOS
- Auto-registers destination when started:

```swift
// In app startup
NSLoggerSupport.start()  // Auto-adds NSLoggerDestination
log.info("ready")        // Sent to both OSLog and NSLogger
```

- NSLogger domain = `subsystem:category` (e.g., `com.example.app:network`)
- Info.plist includes `NSBonjourServices` + `NSLocalNetworkUsageDescription`
- Per-user Bonjour: `NSLoggerSupport.start(useBonjourForBuildUser: true)`
- SSL: `NSLoggerSupport.start(useSSL: true)`

## Notes
- Fail-fast: invalid inputs preconditionFailure
