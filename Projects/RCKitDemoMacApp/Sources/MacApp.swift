import GRDB
import RCKit
import SharedUI
import SwiftUI

#if canImport(MMKV)
    import MMKV
#endif

private let logger = Log.default

@main
struct MacApp: App {
    init() {
        configureLogging()
        configureGRDB()
        configureMMKV()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func configureLogging() {
        NSLoggerSupport.start()
        logger.info("NSLogger started")
    }

    private func configureGRDB() {
        // Access shared instance to trigger initialization and migration
        _ = DemoDatabase.shared
        if let databasePath = DemoDatabase.databasePath {
            logger.info("GRDB ready", metadata: ["path": databasePath])
        }
    }

    private func configureMMKV() {
        #if canImport(MMKV)
            let rootPath = MMKV.initialize(rootDir: nil)
            if rootPath.isEmpty {
                preconditionFailure("MMKV.initialize returned empty path")
            }
            logger.info("MMKV ready", metadata: ["root": rootPath])
        #else
            logger.info("MMKV not linked")
        #endif
    }
}
