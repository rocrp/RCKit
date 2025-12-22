# RCKit

Swift 6.2 + SwiftUI helpers. Tuist-first project.

## Build & Test

```bash
make build    # Generate project + build iOS/macOS
make test     # Run unit tests
make format   # Format code
make lint     # Lint code
make all      # format + lint + test
```

Or manually:
```bash
tuist generate --no-open
xcodebuild -workspace RCKit.xcworkspace -scheme RCKitDemo -destination 'platform=macOS' build
xcodebuild -workspace RCKit.xcworkspace -scheme RCKitDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Swift 6.2 Concurrency

- All targets use `nonisolated` default (no `SWIFT_DEFAULT_ACTOR_ISOLATION`)
- `SWIFT_APPROACHABLE_CONCURRENCY = YES` enabled
- Mark `@Observable` classes with `@MainActor`
- Mark UI-bound code explicitly with `@MainActor`
