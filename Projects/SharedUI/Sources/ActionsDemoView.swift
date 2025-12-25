import RCKit
import SwiftUI

private let logger = Log.default

public struct ActionsDemoView: View {
    public var onRefresh: (() -> Void)?

    public init(onRefresh: (() -> Void)? = nil) {
        self.onRefresh = onRefresh
    }

    public var body: some View {
        Section("Actions") {
            Button("Refresh Demo Values") {
                onRefresh?()
            }
            Button("Log Debug Info") {
                logger.printDebugInfo()
            }
        }
    }
}
