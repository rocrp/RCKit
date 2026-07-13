# Log Destinations: Set-Once Bootstrap + Per-Instance Override; No Mutable Global Registry

Date: 2026-07-13
Status: Accepted

## Context

- `Log` fan-out used a process-global mutable registry (`nonisolated(unsafe) static var _destinations` + `NSLock`), mutated via `addDestination`/`removeAllDestinations` — including as a side effect of `NSLoggerSupport.start()`.
- Consequences: redaction/rendering unobservable in tests (the redaction test asserted nothing), cross-module mutation of Log's state, level gate enforced twice (Log and each destination).

## Decision

- `Log.bootstrap(_ destinations:)` wires default Destinations exactly once at app start; a second call is a programmer error (crash, fail fast).
- `Log.init` accepts an optional `destinations:` override; tests inject a `MemoryDestination` and never bootstrap.
- Log owns the level gate: it delivers only records with `level >= destination.minimumLevel`. Destinations trust it and never re-filter.
- `NSLoggerSupport.start()` returns its destination for the caller to pass to bootstrap; it does not mutate Log.
- Do not reintroduce `addDestination`-style runtime mutation.

## Alternatives Considered

| Option | Result | Reason |
|---|---|---|
| Set-once bootstrap + per-instance override | Chosen | Kills the race and cross-module mutation; tests get injection; apps keep one-line setup |
| Mutable global registry (status quo) | Rejected | `nonisolated(unsafe)` mutation, untestable output, seam leak from NSLoggerSupport |
| Per-instance destinations only (no global) | Rejected | Every `Log(category:)` call site in every app must thread destinations through |
| Depend on apple/swift-log | Rejected | RCKit stays zero-dependency; OSLog remains the primary sink |

## Consequences

- + Redaction and rendering become assertable through `MemoryDestination` (third adapter proves the `LogDestination` seam).
- + One owner for the level-gate invariant.
- - Breaking: `addDestination`/`removeAllDestinations` removed; consuming apps must switch to `bootstrap` (no backward compatibility by policy).
- ? `Log.default` may be touched before bootstrap — destinations must be resolved at log time, not captured at init.

## Notes

- Revisit only if a real use case requires changing destinations mid-process (e.g. user toggling file logging at runtime); that would be a new ADR.
