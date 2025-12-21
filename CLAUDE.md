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

## Swift 6.2 Approachable Concurrency

This project uses Swift 6.2's Approachable Concurrency. Key build settings:

| Target | `SWIFT_APPROACHABLE_CONCURRENCY` | `SWIFT_DEFAULT_ACTOR_ISOLATION` |
|--------|----------------------------------|--------------------------------|
| RCKit (framework) | YES | *(none - nonisolated default)* |
| RCKitDemo (app) | YES | MainActor |
| Tests | YES | *(none)* |

### Writing Code

**For RCKit framework** (library code):
- Default isolation is `nonisolated` - appropriate for libraries
- Mark UI-bound code explicitly with `@MainActor`

**For RCKitDemo app**:
- Default isolation is `MainActor` (SE-0466)
- Data models and database types should be marked `nonisolated` + `Sendable`:
  ```swift
  nonisolated struct MyModel: Sendable, Codable { ... }
  ```
- Use `@concurrent` to explicitly run async functions off the main actor

**Key SE proposals enabled:**
- SE-0461: `nonisolated async` functions run on caller's actor by default
- SE-0470: Protocol conformances inherit actor isolation automatically
- SE-0466: Default actor isolation (MainActor for app targets)
