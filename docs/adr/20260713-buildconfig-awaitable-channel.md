# BuildConfig Channel Is Awaitable and Resolved Once; Sync channelName Removed

Date: 2026-07-13
Status: Accepted

## Context

- TestFlight detection needs StoreKit's `AppTransaction`, which is async-only.
- The previous design cached it in `nonisolated(unsafe) static var _isTestFlight` via a fire-and-forget `Task`: a data race, and early reads of `channelName` in a release build returned `"appstore"` on TestFlight, then silently flipped.
- `#if DEBUG` short-circuits made the TestFlight/App Store logic unreachable from any test.

## Decision

- Channel (`.debug` / `.testflight` / `.appstore`) is exposed as `await BuildConfig.channel()`, resolved exactly once per process.
- Resolution logic is a pure, testable function of (debug build?, sandbox receipt?); the sandbox answer comes through an injectable Channel Probe.
- Sync `channelName` / `isDebugOrTestFlight` are removed. No sync accessor that can return a stale answer will be added back.
- `isDebugging` (sysctl) and `allowDebug` (compile-time) stay sync — they are genuinely synchronous facts.

## Alternatives Considered

| Option | Result | Reason |
|---|---|---|
| Awaitable resolve-once channel | Chosen | No race, no stale first read, testable resolution |
| Cached bool + background Task (status quo) | Rejected | Data race; same question returns two answers |
| Blocking sync resolve at first access | Rejected | Blocks caller (possibly main thread) on StoreKit |
| Persist last-known channel across launches | Deferred | Only if a sync-at-startup consumer actually appears |

## Consequences

- + Callers can never observe a wrong-then-flipped channel.
- - Breaking: consumers of `channelName` (analytics tags, debug UI) must await; UI reads it in a `.task`.
- ? `Log.printDebugInfo()` becomes async since it reports the channel.
