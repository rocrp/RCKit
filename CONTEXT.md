# RCKit

Shared utility library for Apple-platform apps (Swift 6.2, SPM). This context covers the library's own concepts; consuming apps define their own domains on top.

## Language

**Channel**:
The release distribution channel of the running app: `debug`, `testflight`, or `appstore`. Resolved once per process, awaitable; never a snapshot that silently changes.
_Avoid_: environment, build type, flavor

**Channel Probe**:
The injected check behind Channel resolution that answers "is this install a sandbox (TestFlight) receipt?". Real probe asks StoreKit; tests inject a fixed answer.
_Avoid_: TestFlight detector

**Destination**:
A sink that receives rendered log records (file, NSLogger, memory). A Destination receives only records that already passed Log's level gate — it never re-filters.
_Avoid_: sink, handler, appender, backend (for logs)

**Bootstrap**:
The one-time, process-wide wiring of default Destinations at app start. After Bootstrap the Destination set is immutable; tests bypass it by injecting Destinations per Log instance.
_Avoid_: register, addDestination

**Redaction**:
Replacement of secret-bearing metadata values with `<redacted>`, decided by metadata key name (e.g. `password`, `token`).
_Avoid_: masking, scrubbing

**Log Store**:
The seam over the system's historical log archive that LogExporter reads. Real adapter wraps OSLogStore; tests inject an in-memory fake.
_Avoid_: archive, OSLog wrapper

**Keychain Backend**:
The seam over system keychain item operations (add / update / copy / delete). Real adapter calls SecItem*; tests use an in-memory adapter so nothing skips on CI.
_Avoid_: keychain wrapper, store (for keychain)

**XID**:
A globally-unique, time-sortable 12-byte identifier (Go `xid`-compatible), rendered as a 20-character base32 string.
_Avoid_: UUID (when the sortable ID is meant)
