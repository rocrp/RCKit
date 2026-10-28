#if os(iOS)
    import UIKit
#endif

/// Short system feedback. Call from the interaction that deserves it; no global policy.
/// Other platforms accept the same calls without playing feedback.
@MainActor
public enum Haptics {
    public enum ImpactStyle: Sendable {
        case light, medium, heavy, soft, rigid
    }

    public static func selection() {
        #if os(iOS)
            UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    public static func impact(_ style: ImpactStyle) {
        #if os(iOS)
            let native: UIImpactFeedbackGenerator.FeedbackStyle =
                switch style {
                case .light: .light
                case .medium: .medium
                case .heavy: .heavy
                case .soft: .soft
                case .rigid: .rigid
                }
            UIImpactFeedbackGenerator(style: native).impactOccurred()
        #endif
    }

    public static func success() {
        #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    public static func warning() {
        #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    public static func error() {
        #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }
}
