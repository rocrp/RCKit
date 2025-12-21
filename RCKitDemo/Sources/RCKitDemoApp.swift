import RCKit
import SQLiteData
import SwiftUI

#if canImport(MMKV)
    import MMKV
#endif

@main
struct RCKitDemoApp: App {
    init() {
        configureLogging()
        configureSQLiteData()
        configureMMKV()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func configureLogging() {
        #if os(macOS)
            RCKit.log.info("NSLogger disabled on macOS (no dependency linked)")
        #else
            #if canImport(NSLoggerSwift)
                NSLoggerSupport.start()
                RCKit.log.info("NSLogger available: true")
            #else
                RCKit.log.info("NSLogger available: false")
            #endif
        #endif
    }

    private func configureSQLiteData() {
        do {
            try prepareDependencies { values in
                values.defaultDatabase = try SQLiteDataDemoDatabase.makeDatabase()
            }
            if let databasePath = SQLiteDataDemoDatabase.databasePath {
                RCKit.log.info("SQLiteData ready", metadata: ["path": databasePath])
            }
        } catch {
            preconditionFailure("SQLiteData setup failed: \(error)")
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
