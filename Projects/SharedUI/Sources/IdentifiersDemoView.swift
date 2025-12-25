import RCKit
import SwiftUI

public struct IdentifiersDemoView: View {
    @State private var xid: String = ""
    @State private var randomHex: String = ""

    public init() {}

    public var body: some View {
        Section("Identifiers") {
            ValueRow(title: "XID", value: xid)
            ValueRow(title: "Random Hex", value: randomHex)
            Button("Refresh") {
                refresh()
            }
        }
        .task {
            refresh()
        }
    }

    private func refresh() {
        xid = generateXID()
        randomHex = String.randomHex(size: 16)
    }

    private func generateXID() -> String {
        do {
            return try XID.generate()
        } catch {
            preconditionFailure("XID.generate failed: \(error)")
        }
    }
}
