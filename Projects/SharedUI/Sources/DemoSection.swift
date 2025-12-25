import Foundation

public enum DemoSection: String, CaseIterable, Identifiable, Sendable {
    case identifiers
    case color
    case system
    case logging
    case grdb
    case mmkv
    case actions

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .identifiers: "Identifiers"
        case .color: "Color"
        case .system: "System"
        case .logging: "Logging"
        case .grdb: "GRDB"
        case .mmkv: "MMKV"
        case .actions: "Actions"
        }
    }

    public var systemImage: String {
        switch self {
        case .identifiers: "number"
        case .color: "paintpalette"
        case .system: "gear"
        case .logging: "doc.text"
        case .grdb: "cylinder"
        case .mmkv: "externaldrive"
        case .actions: "bolt"
        }
    }
}
