# RCKit

Swift 6.2 utility library. SPM package with Tuist-managed demo apps.

## Structure

```
RCKit/
├── Package.swift           # SPM manifest (library)
├── Sources/RCKit/          # Library sources
├── Tests/RCKitTests/       # Library tests
└── Projects/               # Tuist-managed demo apps
    ├── SharedUI/           # Shared demo UI framework
    ├── RCKitDemoApp/       # iOS demo
    └── RCKitDemoMacApp/    # macOS demo
```

## Build & Test

```bash
# SPM (library only)
swift build
swift test

# Tuist (demo apps)
make generate   # tuist install + generate
make build      # SPM build + demo apps build
make test       # Run unit tests

# Code quality
make format     # Format code
make lint       # Lint code
make all        # format + lint + test
```

## Using RCKit in Other Projects

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/rocrp/RCKit", branch: "main"),
]
```

## Swift 6.2 Concurrency

- `SWIFT_APPROACHABLE_CONCURRENCY = YES` (SE-0461: nonisolated async inherits caller's actor)
- Mark `@Observable` classes with `@MainActor`
- Mark UI-bound code explicitly with `@MainActor`
- Use `@concurrent` to force async off caller's actor when parallel execution needed
