# RCKit

Swift 6.2 + SwiftUI helpers. Pure SPM package with Tuist demo app.

## Build & Test

```bash
# RCKit library (SPM)
swift build       # Build library
swift test        # Run library tests
make build-spm    # Same as swift build
make test-spm     # Same as swift test

# Demo app (Tuist)
make build        # Generate + build demo for macOS/iOS
make test         # Run demo tests
make format       # Format code
make lint         # Lint code
make all          # format + lint + test-spm + test
```

Or manually:
```bash
tuist generate --no-open
xcodebuild -workspace RCKitDemo.xcworkspace -scheme RCKitDemo -destination 'platform=macOS' build
xcodebuild -workspace RCKitDemo.xcworkspace -scheme RCKitDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Swift 6.2 Concurrency

- `SWIFT_APPROACHABLE_CONCURRENCY = YES` (SE-0461: nonisolated async inherits caller's actor)
- Mark `@Observable` classes with `@MainActor`
- Mark UI-bound code explicitly with `@MainActor`
- Use `@concurrent` to force async off caller's actor when parallel execution needed
