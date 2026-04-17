import SwiftUI

/// Centralized animation timing for consistent feel across the app.
extension Animation {
    /// Standard content transition timing (0.2s easeInOut)
    /// Use for: state swaps, tab changes, loading/empty state transitions
    static let appStandard = Animation.easeInOut(duration: 0.2)

    /// Spring animation for interactive elements (response: 0.3, damping: 0.65)
    /// Use for: like button, follow button, filter chip taps
    static let appSpring = Animation.spring(response: 0.3, dampingFraction: 0.65)

    /// Subtle fade for image load-in (0.25s easeIn)
    /// Use for: AsyncImage success phase, avatar fade-in
    static let appFadeIn = Animation.easeIn(duration: 0.25)
}
