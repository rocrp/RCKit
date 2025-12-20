import Foundation
import SwiftUI

#if canImport(MMKV)
import MMKV
#endif

struct MMKVDemoView: View {
  #if canImport(MMKV)
    @State private var inputName: String = ""
    @State private var inputEnabled: Bool = false

    @State private var storedName: String = ""
    @State private var storedEnabled: Bool = false
    @State private var storedUTC: String = ""

    var body: some View {
      Section("Write") {
        TextField("Name", text: $inputName)
          .textInputAutocapitalization(.words)
        Toggle("Enabled", isOn: $inputEnabled)
        Button("Save to MMKV") {
          save()
        }
      }

      Section("Read") {
        ValueRow(title: "Name", value: storedName)
        ValueRow(title: "Enabled", value: storedEnabled ? "true" : "false")
        ValueRow(title: "Saved UTC", value: storedUTC)
        Button("Load from MMKV") {
          load()
        }
      }

      Section("Maintenance") {
        Button("Clear Demo Keys", role: .destructive) {
          clear()
        }
      }
      .task {
        load()
      }
    }

    private func save() {
      let utcString = UTCDateFormatter.iso8601String(from: Date())
      let mmkv = requireMMKV()
      mmkv.set(inputName, forKey: keyName)
      mmkv.set(inputEnabled, forKey: keyEnabled)
      mmkv.set(utcString, forKey: keySavedUTC)
      storedName = inputName
      storedEnabled = inputEnabled
      storedUTC = utcString
    }

    private func load() {
      let mmkv = requireMMKV()
      storedName = mmkv.string(forKey: keyName) ?? ""
      storedEnabled = mmkv.bool(forKey: keyEnabled)
      storedUTC = mmkv.string(forKey: keySavedUTC) ?? ""
    }

    private func clear() {
      let mmkv = requireMMKV()
      mmkv.removeValues(forKeys: [keyName, keyEnabled, keySavedUTC])
      storedName = ""
      storedEnabled = false
      storedUTC = ""
      inputName = ""
      inputEnabled = false
    }

    private func requireMMKV() -> MMKV {
      guard let mmkv = MMKV(mmapID: storageID, mode: .singleProcess) else {
        preconditionFailure("MMKV instance unavailable for id: \(storageID)")
      }
      return mmkv
    }
  #else
    var body: some View {
      Section("MMKV") {
        Text("MMKV not linked. Add the MMKV binary (CocoaPods or custom build) to enable this demo.")
          .foregroundStyle(.secondary)
      }
    }
  #endif
}

#if canImport(MMKV)
private let storageID = "rckit-demo.mmkv"
private let keyName = "demo.name"
private let keyEnabled = "demo.enabled"
private let keySavedUTC = "demo.saved_at_utc"
#endif
