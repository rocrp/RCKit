import RCKit
import SwiftUI

public struct SystemDemoView: View {
    @State private var memory: String = ""
    @State private var channel: BuildConfig.Channel?

    public init() {}

    public var body: some View {
        Section("System") {
            ValueRow(title: "Memory", value: memory)
            ValueRow(title: "Bundle", value: BuildConfig.Bundle.identifier)
            ValueRow(title: "Channel", value: channel?.rawValue ?? "Resolving…")
            Button("Refresh Memory") {
                loadMemory()
            }
        }
        .task {
            channel = await BuildConfig.channel()
            loadMemory()
        }
    }

    private func loadMemory() {
        do {
            memory = try MemoryFootprint.getMemoryUsage().get().formattedString()
        } catch {
            preconditionFailure("MemoryFootprint failed: \(error)")
        }
    }
}
