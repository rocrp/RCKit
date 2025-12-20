# Caveats / Lessons

## Tuist tests
- `tuist test RCKit` runs scheme `RCKit` (framework). No testAction → no tests.
- Use `tuist test RCKitTests`.
- Selective testing can decide “no tests to run”. Fix: `--no-selective-testing`.
- Makefile now uses: `tuist test RCKitTests --no-selective-testing`.
- If scheme still empty, inspect with:
  - `tuist dump` → `schemes[].testAction.targets` should include `RCKitTests`.
  - `xcodebuild -list -workspace RCKit.xcworkspace`.
- Tuist `Scheme` initializer is via static factory: `.scheme(...)` (not `Scheme(...)`).
- Prefer explicit schemes + disable automatic schemes for predictability:
  - `Project(options: .options(automaticSchemesOptions: .disabled), schemes: [...])`.

## Swift 6 concurrency checks
- `ISO8601DateFormatter` is not Sendable → avoid static shared formatter.
  - Fix: build formatter per call (or lock inside actor).
- Global mutable static state (e.g. counters) triggers concurrency errors.
  - Fix: wrap in lock-protected box + `@unchecked Sendable`.
- `UIScreen.main` deprecated in iOS 26, also main-actor isolated.
  - Fix: use `@Environment(\.displayScale)` in SwiftUI or pass `UIScreen` / `UITraitCollection`.

## Keychain tests
- Simulator often lacks entitlement → errSecMissingEntitlement (-34018).
- Fix: probe in `setUpWithError`, `XCTSkip` when unavailable.

## Crypto helpers
- MD5 / SHA1 deprecated. Removed APIs + tests.
  - Keep SHA256/SHA512 only.

## Commands
- Format: `./Scripts/format.sh`
- Lint: `./Scripts/lint.sh`
- Test: `make test`
