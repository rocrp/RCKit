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

Streams logs to [NSLogger](https://github.com/fpillet/NSLogger) desktop viewer via Bonjour.

### Setup

1. Call `NSLoggerSupport.start()` early in app launch (before other destinations):
```swift
#if DEBUG
NSLoggerSupport.start(minimumLevel: .debug)
#endif
```

2. Add to Info.plist:
```xml
<key>NSBonjourServices</key>
<array><string>_nslogger._tcp</string></array>
<key>NSLocalNetworkUsageDescription</key>
<string>Discover NSLogger viewer on local network for live logging.</string>
```

Logs go to both OSLog and NSLogger simultaneously. Domain format: `subsystem:category`.

### Options

- `NSLoggerSupport.start(useBonjourForBuildUser: true)` — per-user Bonjour service name
- `NSLoggerSupport.start(useSSL: true)` — SSL connection

## Notes
- Fail-fast: invalid inputs preconditionFailure
