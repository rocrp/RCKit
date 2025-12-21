import Foundation
import Dependencies
import SwiftUI

struct DependenciesDemoView: View {
    @State private var liveSnapshot = DependencySnapshotValue.empty
    @State private var overrideSnapshot = DependencySnapshotValue.empty

    var body: some View {
        Section("Live Dependencies") {
            ValueRow(title: "App", value: liveSnapshot.appName)
            ValueRow(title: "Environment", value: liveSnapshot.environment)
            ValueRow(title: "UUID", value: liveSnapshot.uuid)
            ValueRow(title: "UTC", value: liveSnapshot.utcNow)
            Button("Generate Live Snapshot") {
                liveSnapshot = DependencySnapshot().snapshot()
            }
        }

        Section("Overridden Dependencies") {
            ValueRow(title: "App", value: overrideSnapshot.appName)
            ValueRow(title: "Environment", value: overrideSnapshot.environment)
            ValueRow(title: "UUID", value: overrideSnapshot.uuid)
            ValueRow(title: "UTC", value: overrideSnapshot.utcNow)
            Button("Generate Overridden Snapshot") {
                overrideSnapshot = makeOverriddenSnapshot()
            }
        }
    }

    private func makeOverriddenSnapshot() -> DependencySnapshotValue {
        let fixedDate = Date(timeIntervalSince1970: 1_725_000_000)
        guard let fixedUUID = UUID(uuidString: "00000000-0000-0000-0000-0000000000F0") else {
            preconditionFailure("Invalid demo UUID constant")
        }

        return withDependencies {
            $0.date.now = fixedDate
            $0.uuid = .constant(fixedUUID)
            $0.demoConfig = DemoConfig(appName: "RCKitDemo", environment: "staging")
        } operation: {
            DependencySnapshot().snapshot()
        }
    }
}

private struct DependencySnapshotValue {
    var appName: String
    var environment: String
    var uuid: String
    var utcNow: String

    static let empty = Self(appName: "-", environment: "-", uuid: "-", utcNow: "-")
}

private struct DependencySnapshot {
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid
    @Dependency(\.demoConfig) var config

    func snapshot() -> DependencySnapshotValue {
        DependencySnapshotValue(
            appName: config.appName,
            environment: config.environment,
            uuid: uuid().uuidString,
            utcNow: UTCDateFormatter.iso8601String(from: now)
        )
    }
}

private struct DemoConfig: Sendable {
    var appName: String
    var environment: String
}

private enum DemoConfigKey: DependencyKey {
    static let liveValue = DemoConfig(appName: "RCKitDemo", environment: "live")
}

private extension DependencyValues {
    var demoConfig: DemoConfig {
        get { self[DemoConfigKey.self] }
        set { self[DemoConfigKey.self] = newValue }
    }
}
