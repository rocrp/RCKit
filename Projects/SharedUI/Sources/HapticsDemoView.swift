import RCKit
import SwiftUI

struct HapticsDemoView: View {
    var body: some View {
        Section {
            Text("Try these on an iPhone that supports haptics. Mac, Watch and the simulator do not play feedback here.")
                .foregroundStyle(.secondary)
        }
        Section("Selection") {
            Button("Selection changed") { Haptics.selection() }
        }
        Section("Impact") {
            Button("Light") { Haptics.impact(.light) }
            Button("Medium") { Haptics.impact(.medium) }
            Button("Heavy") { Haptics.impact(.heavy) }
            Button("Soft") { Haptics.impact(.soft) }
            Button("Rigid") { Haptics.impact(.rigid) }
        }
        Section("Outcome") {
            Button("Success") { Haptics.success() }
            Button("Warning") { Haptics.warning() }
            Button("Error") { Haptics.error() }
        }
    }
}
