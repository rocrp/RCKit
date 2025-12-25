import GRDB
import RCKit
import SharedUI
import UIKit

#if canImport(MMKV)
    import MMKV
#endif

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureLogging()
        configureGRDB()
        configureMMKV()
        return true
    }

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }

    // MARK: - Configuration

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
