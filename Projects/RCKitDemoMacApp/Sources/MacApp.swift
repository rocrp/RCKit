import GRDB
import RCKit
import SharedUI
import SwiftUI

#if canImport(MMKV)
    import MMKV
#endif

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
        #if canImport(NSLogger)
            NSLoggerSupport.start()
            RCKit.log.info("NSLogger available: true")
        #else
            RCKit.log.info("NSLogger available: false")
        #endif
    }

    private func configureGRDB() {
        // Access shared instance to trigger initialization and migration
        _ = DemoDatabase.shared
        if let databasePath = DemoDatabase.databasePath {
            RCKit.log.info("GRDB ready", metadata: ["path": databasePath])
        }
    }

    private func configureMMKV() {
        #if canImport(MMKV)
            let rootPath = MMKV.initialize(rootDir: nil)
            if rootPath.isEmpty {
                preconditionFailure("MMKV.initialize returned empty path")
            }
            RCKit.log.info("MMKV ready", metadata: ["root": rootPath])
        #else
            RCKit.log.info("MMKV not linked")
        #endif
    }
}
