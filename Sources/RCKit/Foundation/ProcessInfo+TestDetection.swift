import Foundation

public extension ProcessInfo {
    var isRunningTests: Bool {
        let env = environment
        if env["XCTestConfigurationFilePath"] != nil
            || env["XCTestBundlePath"] != nil
            || env["XCTestSessionIdentifier"] != nil
            || env["XCInjectBundleInto"] != nil
        {
            return true
        }

        if env["DYLD_INSERT_LIBRARIES"]?.contains("XCTest") == true {
            return true
        }

        if Bundle.allBundles.contains(where: { $0.bundleURL.pathExtension == "xctest" }) {
            return true
        }

        if NSClassFromString("XCTestCase") != nil {
            return true
        }

        return false
    }
}
