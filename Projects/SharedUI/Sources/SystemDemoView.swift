import RCKit
import SwiftUI

public struct SystemDemoView: View {
    @State private var memory: String = ""

    public init() {}

    public var body: some View {
        Section("System") {
            ValueRow(title: "Memory", value: memory)
            ValueRow(title: "Bundle", value: BuildConfig.Bundle.identifier)
            ValueRow(title: "Channel", value: BuildConfig.channelName)
            Button("Refresh Memory") {
                loadMemory()
            }
        }
        .task {
            loadMemory()
        }
    }

    private func loadMemory() {
        do {
            memory = try MemoryFootprint.getFormattedMemoryUsage()
        } catch {
            preconditionFailure("MemoryFootprint failed: \(error)")
        }
    }
}
