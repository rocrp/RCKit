# RCKit

Swift 6.2 + SwiftUI helpers. Tuist-managed project (iOS + macOS).

## Build & Test

```bash
make build    # Generate project + build iOS/macOS
make test     # Run unit tests (macOS)
make format   # Format code
make lint     # Lint code
make all      # format + lint + test
```

Or manually:
```bash
tuist generate --no-open
tuist test RCKitTests --platform macOS
xcodebuild -workspace RCKit.xcworkspace -scheme RCKitDemo -destination 'platform=macOS' build
xcodebuild -workspace RCKit.xcworkspace -scheme RCKitDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Swift 6.2 Concurrency

- `SWIFT_APPROACHABLE_CONCURRENCY = YES` (SE-0461: nonisolated async inherits caller's actor)
- Mark `@Observable` classes with `@MainActor`
- Mark UI-bound code explicitly with `@MainActor`
- Use `@concurrent` to force async off caller's actor when parallel execution needed
