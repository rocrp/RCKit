import RCKit
import SwiftUI

struct ContentView: View {
    @State private var xid: String = ""
    @State private var memory: String = ""
    @State private var randomHex: String = ""
    @State private var color: Color = .random()

    var body: some View {
        NavigationSplitView {
            sidebar()
        } detail: {
            Text("Select a section")
                .foregroundStyle(.secondary)
        }
        .task {
            refresh()
        }
    }

    private func sidebar() -> some View {
        List {
            ForEach(DemoSection.allCases) { section in
                NavigationLink {
                    detailView(for: section)
                } label: {
                    Text(section.title)
                }
            }
        }
        .navigationTitle("RCKit Demo")
        #if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .listStyle(.sidebar)
        #endif
    }

    private func detailView(for section: DemoSection) -> some View {
        List {
            sectionContent(for: section)
        }
        .navigationTitle(section.title)
    }

    @ViewBuilder
    private func sectionContent(for section: DemoSection) -> some View {
        switch section {
        case .identifiers:
            identifiersRows()
        case .color:
            colorRows()
        case .system:
            systemRows()
        case .grdb:
            GRDBDemoView()
        case .mmkv:
            MMKVDemoView()
        case .actions:
            actionRows()
        }
    }

    @ViewBuilder
    private func identifiersRows() -> some View {
        ValueRow(title: "XID", value: xid)
        ValueRow(title: "Random Hex", value: randomHex)
    }

    @ViewBuilder
    private func colorRows() -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.secondary.opacity(0.3)))
            ValueRow(title: "Hex", value: color.hex())
        }
        Button("Randomize Color") {
            color = .random()
            RCKit.log.info("Randomized color", metadata: ["hex": color.hex()])
        }
    }

    @ViewBuilder
    private func systemRows() -> some View {
        ValueRow(title: "Memory", value: memory)
        ValueRow(title: "Bundle", value: BuildConfig.Bundle.identifier)
        ValueRow(title: "Channel", value: BuildConfig.channelName)
    }

    @ViewBuilder
    private func actionRows() -> some View {
        Button("Refresh Demo Values") {
            refresh()
        }
        Button("Log Debug Info") {
            RCKit.log.printDebugInfo()
        }
    }

    private func refresh() {
        xid = generateXID()
        randomHex = String.randomHex(size: 16)
        memory = loadMemory()
    }

    private func generateXID() -> String {
        do {
            return try XID.generate()
        } catch {
            preconditionFailure("XID.generate failed: \(error)")
        }
    }

    private func loadMemory() -> String {
        do {
            return try MemoryFootprint.getFormattedMemoryUsage()
        } catch {
            preconditionFailure("MemoryFootprint failed: \(error)")
        }
    }
}

private enum DemoSection: String, CaseIterable, Identifiable {
    case identifiers
    case color
    case system
    case grdb
    case mmkv
    case actions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .identifiers: return "Identifiers"
        case .color: return "Color"
        case .system: return "System"
        case .grdb: return "GRDB"
        case .mmkv: return "MMKV"
        case .actions: return "Actions"
        }
    }
}
