import Foundation
import Testing

@testable import RCKit

struct LogTests {
    @Test func logSmokeTest() {
        Log.default.info("log smoke test")
        Log.default.debug("debug message")
        Log.default.warning("warning message")
        Log.default.error("error message")
        Log.default.error("error with error", error: NSError(domain: "test", code: 1))
        // Note: printDebugInfo() requires Bundle.main context, skip in unit tests
    }

    @Test func logWithMetadata() {
        let log = Log(category: "test")
        log.info("with metadata", metadata: ["key": "value", "number": 42])
    }

    @Test func commonRedactionRendersSortedMetadataIntoDestination() {
        let destination = MemoryDestination(capacity: 10)
        let log = Log(
            subsystem: "dev.rocry.test",
            category: "authentication",
            redactionMode: .common,
            destinations: [destination]
        )

        log.info(
            "login attempt",
            metadata: ["user": "john", "password": "secret123", "attempt": 3],
            file: "Authentication/Login.swift",
            function: "signIn()",
            line: 42
        )

        #expect(
            destination.entries == [
                MemoryDestination.Entry(
                    level: .info,
                    message: "login attempt [attempt=3 password=<redacted> user=john]",
                    subsystem: "dev.rocry.test",
                    category: "authentication",
                    file: "Authentication/Login.swift",
                    line: 42,
                    function: "signIn()"
                )
            ]
        )
    }

    @Test func keyRedactionMatchesCaseInsensitively() {
        let destination = MemoryDestination(capacity: 10)
        let log = Log(
            minimumLevel: .debug,
            redactionMode: .keys(["AccessToken"]),
            destinations: [destination]
        )

        log.debug(
            "request",
            metadata: ["ACCESSTOKEN": "secret", "path": "/profile"]
        )

        #expect(destination.entries.map(\.message) == ["request [ACCESSTOKEN=<redacted> path=/profile]"])
    }

    @Test func bootstrapResolvesAtLogTimeAndInstanceOverrideWins() async {
        await #expect(processExitsWith: .success) {
            let bootstrappedDestination = MemoryDestination(capacity: 10)
            let overrideDestination = MemoryDestination(capacity: 10)
            let preBootstrapLog = Log.default
            let overrideLog = Log(
                minimumLevel: .debug,
                destinations: [overrideDestination]
            )

            Log.bootstrap([bootstrappedDestination])
            preBootstrapLog.notice("bootstrapped")
            overrideLog.info("override")

            precondition(
                bootstrappedDestination.entries.map(\.message) == ["bootstrapped"]
            )
            precondition(overrideDestination.entries.map(\.message) == ["override"])
        }
    }

    @Test func bootstrapCrashesOnSecondCall() async {
        await #expect(processExitsWith: .failure) {
            Log.bootstrap([])
            Log.bootstrap([])
        }
    }

    @Test func logAppliesDestinationMinimumLevel() {
        let destination = MemoryDestination(capacity: 10, minimumLevel: .warning)
        let log = Log(minimumLevel: .debug, destinations: [destination])

        log.info("below destination gate")
        log.warning("passes destination gate")

        #expect(destination.entries.map(\.message) == ["passes destination gate"])
    }

    @Test func memoryDestinationTrustsLogLevelGate() {
        let destination = MemoryDestination(capacity: 10, minimumLevel: .fault)

        destination.send(
            level: .debug,
            message: "already gated",
            subsystem: "dev.rocry.test",
            category: "test",
            file: "Test.swift",
            line: 1,
            function: "test()"
        )

        #expect(destination.entries.map(\.message) == ["already gated"])
    }

    @Test func memoryDestinationKeepsNewestEntriesWithinCapacity() {
        let destination = MemoryDestination(capacity: 2)
        let log = Log(minimumLevel: .debug, destinations: [destination])

        log.info("first")
        log.info("second")
        log.info("third")

        #expect(destination.entries.map(\.message) == ["second", "third"])
    }

    @Test func logLevelComparison() {
        #expect(LogLevel.debug < LogLevel.info)
        #expect(LogLevel.info < LogLevel.notice)
        #expect(LogLevel.notice < LogLevel.warning)
        #expect(LogLevel.warning < LogLevel.error)
        #expect(LogLevel.error < LogLevel.fault)
    }
}
