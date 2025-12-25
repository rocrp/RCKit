import SwiftUI

/// A SwiftUI view that displays the content for a given demo section.
/// Used by both iOS (via UIHostingController) and macOS apps.
public struct DemoContentView: View {
    public let section: DemoSection

    public init(section: DemoSection) {
        self.section = section
    }

    public var body: some View {
        List {
            content
        }
        .navigationTitle(section.title)
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .identifiers:
            IdentifiersDemoView()
        case .color:
            ColorDemoView()
        case .system:
            SystemDemoView()
        case .logging:
            LogDemoView()
        case .grdb:
            GRDBDemoView()
        case .mmkv:
            MMKVDemoView()
        case .actions:
            ActionsDemoView()
        }
    }
}
