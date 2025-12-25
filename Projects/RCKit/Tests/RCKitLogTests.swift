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
        Log.default.printDebugInfo()
    }

    @Test func logWithMetadata() {
        let log = Log(category: "test")
        log.info("with metadata", metadata: ["key": "value", "number": 42])
    }

    @Test func logRedaction() {
        let log = Log(category: "test", redactionMode: .common)
        // password should be redacted
        log.info("login attempt", metadata: ["user": "john", "password": "secret123"])
    }

    @Test func logLevelComparison() {
        #expect(LogLevel.debug < LogLevel.info)
        #expect(LogLevel.info < LogLevel.notice)
        #expect(LogLevel.notice < LogLevel.warning)
        #expect(LogLevel.warning < LogLevel.error)
        #expect(LogLevel.error < LogLevel.fault)
    }
}
