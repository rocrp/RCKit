import RCKit
import SwiftUI

struct ContentView: View {
  @State private var xid: String = ""
  @State private var utcJSON: String = ""
  @State private var memory: String = ""
  @State private var randomHex: String = ""
  @State private var color: Color = .random()
  @State private var relativeTime: String = ""

  var body: some View {
    NavigationView {
      List {
        Section("Identifiers") {
          ValueRow(title: "XID", value: xid)
          ValueRow(title: "Random Hex", value: randomHex)
        }

        Section("Time") {
          ValueRow(title: "UTC JSON", value: utcJSON)
          ValueRow(title: "Relative", value: relativeTime)
        }

        Section("Color") {
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

        Section("System") {
          ValueRow(title: "Memory", value: memory)
          ValueRow(title: "Bundle", value: BuildConfig.Bundle.identifier)
          ValueRow(title: "Channel", value: BuildConfig.channelName)
        }

        Section("Actions") {
          Button("Refresh Demo Values") {
            refresh()
          }
          Button("Log Debug Info") {
            RCKit.log.printDebugInfo()
          }
        }
      }
        .navigationTitle("RCKit Demo")
      .task {
        refresh()
      }
    }
  }

  private func refresh() {
    xid = generateXID()
    randomHex = String.randomHex(size: 16)
    relativeTime = Date().addingTimeInterval(-3_600).relativeShortString()
    utcJSON = encodeUTCJSON()
    memory = loadMemory()
  }

  private func generateXID() -> String {
    do {
      return try XID.generate()
    } catch {
      preconditionFailure("XID.generate failed: \(error)")
    }
  }

  private func encodeUTCJSON() -> String {
    struct TimestampPayload: Codable {
      let id: String
      let createdAt: Date
    }

    let payload = TimestampPayload(id: xid, createdAt: Date())
    do {
      let data = try JSONCoding.makeEncoder().encode(payload)
      guard let string = String(data: data, encoding: .utf8) else {
        preconditionFailure("Failed to decode UTF-8 JSON payload")
      }
      return string
    } catch {
      preconditionFailure("JSON encoding failed: \(error)")
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

#Preview {
  ContentView()
}
