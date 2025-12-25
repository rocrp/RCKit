import RCKit
import SwiftUI

public struct LogDemoView: View {
    @State private var logEntries: [LogEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var exportedURL: URL?

    private let log = Log(category: "demo")

    public init() {}

    public var body: some View {
        Section("Log Actions") {
            Button("Log Debug") {
                log.debug("This is a debug message")
            }
            Button("Log Info") {
                log.info("This is an info message", metadata: ["source": "demo"])
            }
            Button("Log Warning") {
                log.warning("This is a warning message")
            }
            Button("Log Error") {
                log.error("This is an error message", error: DemoError.sampleError)
            }
        }

        Section("Export Logs") {
            Button("Fetch Recent Logs") {
                Task { await fetchLogs() }
            }
            .disabled(isLoading)

            Button("Export to File") {
                Task { await exportToFile() }
            }
            .disabled(isLoading)

            if isLoading {
                HStack {
                    ProgressView()
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            if let exportedURL {
                ShareLink(item: exportedURL) {
                    Label("Share Exported Log", systemImage: "square.and.arrow.up")
                }
            }
        }

        if !logEntries.isEmpty {
            Section("Recent Logs (\(logEntries.count))") {
                ForEach(logEntries.indices, id: \.self) { index in
                    LogEntryRow(entry: logEntries[index])
                }
            }
        }
    }

    @MainActor
    private func fetchLogs() async {
        isLoading = true
        errorMessage = nil

        do {
            let since = Date.now.addingTimeInterval(-300)  // last 5 minutes
            logEntries = try await LogExporter.fetch(since: since)
        } catch {
            errorMessage = "Failed to fetch: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    private func exportToFile() async {
        isLoading = true
        errorMessage = nil

        do {
            let since = Date.now.addingTimeInterval(-3600)  // last hour
            exportedURL = try await LogExporter.exportToFile(since: since)
        } catch {
            errorMessage = "Failed to export: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

private struct LogEntryRow: View {
    let entry: LogEntry

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.level.symbol)
                Text(entry.level.label)
                    .font(.caption.bold())
                    .foregroundStyle(levelColor)
                Spacer()
                Text(timeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(entry.message)
                .font(.caption)
                .lineLimit(3)
            Text("\(entry.subsystem):\(entry.category)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var levelColor: Color {
        switch entry.level {
        case .debug: .gray
        case .info: .blue
        case .notice: .primary
        case .warning: .orange
        case .error, .fault: .red
        }
    }
}

private enum DemoError: Error, LocalizedError {
    case sampleError

    var errorDescription: String? {
        "This is a sample error for demonstration"
    }
}
