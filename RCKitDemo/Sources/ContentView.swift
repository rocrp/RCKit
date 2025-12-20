import RCKit
import SwiftUI

struct ContentView: View {
  @State private var xid: String = ""
  @State private var memory: String = ""
  @State private var randomHex: String = ""
  @State private var color: Color = .random()
  @State private var relativeTime: String = ""
  #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  #endif

  var body: some View {
    rootView()
      .task {
        refresh()
      }
  }

  @ViewBuilder
  private func rootView() -> some View {
    #if os(iOS)
      if horizontalSizeClass == .compact {
        NavigationStack {
          sidebarList(compact: true)
        }
      } else {
        splitView()
      }
    #else
      splitView()
    #endif
  }

  private func splitView() -> some View {
    NavigationSplitView {
      sidebarList(compact: false)
    } detail: {
      Text("Select a section")
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private func sidebarList(compact: Bool) -> some View {
    #if os(iOS)
      if compact {
        listContent()
          .navigationTitle("RCKit Demo")
          .listStyle(.plain)
      } else {
        listContent()
          .navigationTitle("RCKit Demo")
      }
    #else
      listContent()
        .navigationTitle("RCKit Demo")
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        .listStyle(.sidebar)
    #endif
  }

  private func listContent() -> some View {
    List {
      ForEach(DemoSection.allCases) { section in
        NavigationLink {
          detailView(for: section)
        } label: {
          Text(section.title)
        }
      }
    }
  }

  private func detailView(for section: DemoSection) -> some View {
    ScrollView {
      sectionContent(for: section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
    }
    .navigationTitle(section.title)
  }

  @ViewBuilder
  private func sectionContent(for section: DemoSection) -> some View {
    switch section {
    case .identifiers:
      identifiersRows()
    case .time:
      timeRows()
    case .color:
      colorRows()
    case .system:
      systemRows()
    case .actions:
      actionRows()
    }
  }

  private func identifiersRows() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      ValueRow(title: "XID", value: xid)
      ValueRow(title: "Random Hex", value: randomHex)
    }
  }

  private func timeRows() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      ValueRow(title: "Relative", value: relativeTime)
    }
  }

  private func colorRows() -> some View {
    VStack(alignment: .leading, spacing: 12) {
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
  }

  private func systemRows() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      ValueRow(title: "Memory", value: memory)
      ValueRow(title: "Bundle", value: BuildConfig.Bundle.identifier)
      ValueRow(title: "Channel", value: BuildConfig.channelName)
    }
  }

  private func actionRows() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Button("Refresh Demo Values") {
        refresh()
      }
      Button("Log Debug Info") {
        RCKit.log.printDebugInfo()
      }
    }
  }

  private func refresh() {
    xid = generateXID()
    randomHex = String.randomHex(size: 16)
    relativeTime = Date().addingTimeInterval(-3_600).relativeShortString()
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
  case time
  case color
  case system
  case actions

  var id: String { rawValue }

  var title: String {
    switch self {
    case .identifiers: return "Identifiers"
    case .time: return "Time"
    case .color: return "Color"
    case .system: return "System"
    case .actions: return "Actions"
    }
  }
}

private struct ValueRow: View {
  let title: String
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.system(.body, design: .monospaced))
        .foregroundStyle(.primary)
    }
    .padding(.vertical, 2)
  }
}
