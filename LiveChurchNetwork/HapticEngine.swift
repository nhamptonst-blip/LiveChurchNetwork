import UIKit

/// Centralized haptic feedback engine for consistent tactile feedback across the app.
struct HapticEngine {
    /// Impact haptic with specified intensity
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// Notification haptic (success, warning, error)
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    /// Selection changed haptic (for picker, toggle, filter selection)
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
