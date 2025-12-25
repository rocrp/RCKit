import RCKit
import SwiftUI

private let logger = Log.default

public struct ColorDemoView: View {
    @State private var color: Color = .random()

    public init() {}

    public var body: some View {
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
                logger.info("Randomized color", metadata: ["hex": color.hex()])
            }
        }
    }
}
