import Foundation
import Testing

@testable import RCKit

struct LogTests {
    @Test func logSmokeTest() {
        RCKit.log.info("log smoke test")
        RCKit.log.debug("debug message")
        RCKit.log.warning("warning message")
        RCKit.log.error("error message")
        RCKit.log.error("error with error", error: NSError(domain: "test", code: 1))
        RCKit.log.printDebugInfo()
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
