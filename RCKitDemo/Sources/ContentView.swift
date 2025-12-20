import RCKit
import SwiftUI

struct ContentView: View {
  @State private var xid: String = ""
  @State private var utcNow: String = ""
  @State private var memory: String = ""
  @State private var randomHex: String = ""
  @State private var color: Color = .random()
  @State private var relativeTime: String = ""
  #if os(macOS)
    @State private var selection: DemoSection? = .identifiers
  #endif

  var body: some View {
    rootView()
      .task {
        refresh()
      }
  }

  @ViewBuilder
  private func rootView() -> some View {
    #if os(macOS)
      NavigationSplitView {
        List(DemoSection.allCases, selection: $selection) { section in
          Text(section.title)
            .tag(section)
        }
        .navigationTitle("RCKit Demo")
        .listStyle(.sidebar)
      } detail: {
        if let selection {
          macDetailView(for: selection)
            .navigationTitle(selection.title)
        } else {
          Text("Select a section")
            .foregroundStyle(.secondary)
        }
      }
      .navigationSplitViewStyle(.balanced)
      .frame(minWidth: 720, minHeight: 520)
    #else
      NavigationStack {
        listView()
          .navigationTitle("RCKit Demo")
      }
    #endif
  }

  private func listView() -> some View {
    List {
      Section(DemoSection.identifiers.title) {
        identifiersRows()
      }

      Section(DemoSection.time.title) {
        timeRows()
      }

      Section(DemoSection.color.title) {
        colorRows()
      }

      Section(DemoSection.system.title) {
        systemRows()
      }

      Section(DemoSection.actions.title) {
        actionRows()
      }
    }
  }

  private func macDetailView(for section: DemoSection) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text(section.title)
          .font(.title2)
          .fontWeight(.semibold)

        VStack(alignment: .leading, spacing: 12) {
          sectionContent(for: section)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(24)
    }
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

  @ViewBuilder
  private func identifiersRows() -> some View {
    ValueRow(title: "XID", value: xid)
    ValueRow(title: "Random Hex", value: randomHex)
  }

  @ViewBuilder
  private func timeRows() -> some View {
    ValueRow(title: "UTC Now", value: utcNow)
    ValueRow(title: "Relative", value: relativeTime)
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
    relativeTime = Date().addingTimeInterval(-3_600).relativeShortString()
    utcNow = utcISO8601String(from: Date())
    memory = loadMemory()
  }

  private func utcISO8601String(from date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
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
