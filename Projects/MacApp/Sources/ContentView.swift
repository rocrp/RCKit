import SharedUI
import SwiftUI

struct ContentView: View {
    @State private var selectedSection: DemoSection? = .identifiers

    var body: some View {
        NavigationSplitView {
            sidebar()
        } detail: {
            detailView()
        }
    }

    private func sidebar() -> some View {
        List(DemoSection.allCases, selection: $selectedSection) { section in
            Label(section.title, systemImage: section.systemImage)
                .tag(section)
        }
        .navigationTitle("RCKit Demo")
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private func detailView() -> some View {
        if let section = selectedSection {
            DemoContentView(section: section)
        } else {
            Text("Select a section")
                .foregroundStyle(.secondary)
        }
    }
}
