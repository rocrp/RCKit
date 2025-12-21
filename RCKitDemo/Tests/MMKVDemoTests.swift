import Foundation
import XCTest

#if canImport(MMKV)
    import MMKV
#endif

final class MMKVDemoTests: XCTestCase {
    func testBasicReadWrite() throws {
        #if canImport(MMKV)
            let rootURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)

            let rootPath = MMKV.initialize(rootDir: rootURL.path)
            XCTAssertFalse(rootPath.isEmpty)

            guard let mmkv = MMKV(mmapID: "rckit.demo.tests", rootPath: rootPath) else {
                XCTFail("MMKV init failed")
                return
            }

            let utc = UTCDateFormatter.iso8601String(from: Date(timeIntervalSince1970: 0))
            mmkv.set(true, forKey: "flag")
            mmkv.set(utc, forKey: "saved_at_utc")

            XCTAssertTrue(mmkv.bool(forKey: "flag"))
            XCTAssertEqual(mmkv.string(forKey: "saved_at_utc"), utc)
        #else
            throw XCTSkip("MMKV not linked")
        #endif
    }
}
