import Foundation
import StoreKit
import UIKit

// MARK: - In-App Review Prompt
//
// Wraps `SKStoreReviewController.requestReview` and gates it on positive
// moments — only ever after the user just did something they enjoyed
// (created their first post, hit 3 follows, finished onboarding). Apple
// caps display to 3 prompts per 365 days per user; we layer our own
// throttle on top so we don't waste those impressions on small wins.
//
// Every meaningful "trigger" we want to consider gets called via
// `recordTrigger(_:)`. The service decides whether enough has happened
// and whether enough time has passed since the last prompt before
// asking the system to display it.

enum ReviewPromptService {

    /// Triggers worth scoring. Most are worth 1 point; a few high-signal
    /// moments (creating a post, completing onboarding) are worth 2.
    enum Trigger {
        case completedOnboarding
        case followedChurch
        case followedPerson
        case createdPost
        case createdEvent
        case sentInquiry
        case repliedToInquiry
        case viewedFeed
        case rsvpedToEvent

        var points: Int {
            switch self {
            case .completedOnboarding,
                 .createdPost,
                 .createdEvent,
                 .repliedToInquiry:
                return 2
            case .followedChurch,
                 .followedPerson,
                 .sentInquiry,
                 .rsvpedToEvent:
                return 1
            case .viewedFeed:
                return 0  // Tracked for cooldown bookkeeping but not scored.
            }
        }
    }

    private static let pointsKey            = "lcn.reviewPrompt.score"
    private static let lastShownAtKey       = "lcn.reviewPrompt.lastShownAt"
    private static let firstLaunchKey       = "lcn.reviewPrompt.firstLaunchAt"
    private static let promptedThisVersion  = "lcn.reviewPrompt.versionPrompted"

    /// Score required before we'll consider asking. Calibrated so a
    /// typical engaged session crosses it after ~3-4 meaningful actions.
    private static let scoreThreshold = 5

    /// Don't ask again for at least 90 days, even though Apple's own
    /// cap is 365/year × 3.
    private static let minDaysBetweenPrompts: TimeInterval = 60 * 60 * 24 * 90

    /// Don't ask within the user's first day on the app — give the
    /// experience time to land before requesting an evaluation.
    private static let minDaysSinceFirstLaunch: TimeInterval = 60 * 60 * 24 * 1

    /// Call from anywhere a meaningful action just succeeded. Cheap; no
    /// network and no UI unless the prompt actually fires.
    static func recordTrigger(_ trigger: Trigger) {
        // Stamp first launch on the very first call so we have a
        // reference for the "newness" gate below.
        let defaults = UserDefaults.standard
        if defaults.double(forKey: firstLaunchKey) == 0 {
            defaults.set(Date().timeIntervalSince1970, forKey: firstLaunchKey)
        }

        let earned = trigger.points
        if earned > 0 {
            defaults.set(defaults.integer(forKey: pointsKey) + earned, forKey: pointsKey)
        }

        if shouldShowPrompt() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                requestReview()
            }
        }
    }

    private static func shouldShowPrompt() -> Bool {
        let defaults = UserDefaults.standard

        // Score gate.
        guard defaults.integer(forKey: pointsKey) >= scoreThreshold else { return false }

        // Newness gate.
        let firstLaunch = defaults.double(forKey: firstLaunchKey)
        if firstLaunch > 0 {
            let elapsed = Date().timeIntervalSince1970 - firstLaunch
            if elapsed < minDaysSinceFirstLaunch { return false }
        }

        // Cooldown gate.
        let lastShown = defaults.double(forKey: lastShownAtKey)
        if lastShown > 0 {
            let elapsed = Date().timeIntervalSince1970 - lastShown
            if elapsed < minDaysBetweenPrompts { return false }
        }

        // Per-version gate — Apple shows the prompt at most once per
        // CFBundleShortVersionString. Track that ourselves so we don't
        // even ask iOS to suppress.
        let version = Bundle.main
            .infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        if defaults.string(forKey: promptedThisVersion) == version { return false }

        return true
    }

    @MainActor
    private static func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }
        SKStoreReviewController.requestReview(in: scene)

        let defaults = UserDefaults.standard
        defaults.set(Date().timeIntervalSince1970, forKey: lastShownAtKey)
        defaults.set(0, forKey: pointsKey)
        let version = Bundle.main
            .infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        defaults.set(version, forKey: promptedThisVersion)
    }
}
