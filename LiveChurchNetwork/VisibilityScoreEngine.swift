import Foundation

/// Single source of truth for the church visibility score on iOS.
/// 1:1 port of src/lib/visibility-score.ts — keep in lockstep with web.

struct VisibilityFactor: Identifiable, Hashable {
    let key: String
    let label: String
    let weight: Int
    let done: Bool
    let tip: String
    let actionLabel: String   // e.g. "Edit profile", "Create post"

    var id: String { key }
}

enum VisibilityTier: String {
    case excellent  = "Excellent"
    case strong     = "Strong"
    case building   = "Building"
    case gettingStarted = "Getting Started"
}

struct VisibilityResult {
    let score: Int          // 0-100
    let earned: Int
    let totalWeight: Int
    let factors: [VisibilityFactor]
    let remaining: [VisibilityFactor]   // sorted weight desc
    let tier: VisibilityTier
}

enum VisibilityScoreEngine {

    /// Signals from the surrounding query state — kept separate from the
    /// church row itself so the engine doesn't need a Supabase client.
    struct Signals {
        let recentPostCount: Int
        let upcomingEventCount: Int
    }

    static func compute(_ church: ChurchSubmission?, signals: Signals) -> VisibilityResult {
        let services: [ServiceTime] = {
            if let s = church?.serviceTimesJson, !s.isEmpty { return s }
            return ScheduleHelpers.parseLegacyServiceTimes(church?.serviceTimes)
        }()
        let hasServiceTimes = !services.isEmpty || !(church?.serviceTimes ?? "").isEmpty
        let hasSocial = [
            church?.facebookUrl, church?.instagramUrl, church?.youtubeUrl,
            church?.xUrl, church?.tiktokUrl
        ].contains { $0?.isEmpty == false }

        let factors: [VisibilityFactor] = [
            VisibilityFactor(
                key: "logo",
                label: "Church logo",
                weight: 8,
                done: !(church?.avatarUrl ?? "").isEmpty,
                tip: "A logo makes you instantly recognizable in feeds and search.",
                actionLabel: "Edit profile"
            ),
            VisibilityFactor(
                key: "cover",
                label: "Cover photo",
                weight: 8,
                done: !(church?.coverUrl ?? "").isEmpty,
                tip: "Cover photos lift profile views by ~30%.",
                actionLabel: "Edit profile"
            ),
            VisibilityFactor(
                key: "about",
                label: "Description",
                weight: 10,
                done: !(church?.about ?? "").isEmpty,
                tip: "Tell visitors who you are — beliefs, history, what to expect.",
                actionLabel: "Edit profile"
            ),
            VisibilityFactor(
                key: "service",
                label: "Service times",
                weight: 14,
                done: hasServiceTimes,
                tip: "Visitors look for service times first. Add them to land in search.",
                actionLabel: "Edit profile"
            ),
            VisibilityFactor(
                key: "livestream",
                label: "Livestream link",
                weight: 12,
                done: !(church?.livestreamUrl ?? "").isEmpty,
                tip: "Adds a Live badge to your profile and unlocks Go Live.",
                actionLabel: "Edit profile"
            ),
            VisibilityFactor(
                key: "website",
                label: "Website",
                weight: 6,
                done: !(church?.website ?? "").isEmpty,
                tip: "External link drives credibility and lets visitors dig deeper.",
                actionLabel: "Edit profile"
            ),
            VisibilityFactor(
                key: "social",
                label: "Social links",
                weight: 6,
                done: hasSocial,
                tip: "Connecting socials boosts cross-platform follower growth.",
                actionLabel: "Edit profile"
            ),
            VisibilityFactor(
                key: "donations",
                label: "Donation link",
                weight: 8,
                done: !(church?.donationUrl ?? "").isEmpty,
                tip: "Make giving easy — donation links convert at higher rates.",
                actionLabel: "Edit profile"
            ),
            VisibilityFactor(
                key: "posts",
                label: "Recent posts",
                weight: 14,
                done: signals.recentPostCount > 0,
                tip: "Churches with weekly posts get 4× more engagement.",
                actionLabel: "Create post"
            ),
            VisibilityFactor(
                key: "events",
                label: "Upcoming events",
                weight: 14,
                done: signals.upcomingEventCount > 0,
                tip: "Events drive RSVPs and bring members back to your page.",
                actionLabel: "Create event"
            ),
        ]

        let totalWeight = factors.reduce(0) { $0 + $1.weight }
        let earned = factors.filter { $0.done }.reduce(0) { $0 + $1.weight }
        let score = totalWeight > 0 ? Int((Double(earned) / Double(totalWeight) * 100.0).rounded()) : 0
        let remaining = factors.filter { !$0.done }.sorted { $0.weight > $1.weight }

        let tier: VisibilityTier
        switch score {
        case 90...:    tier = .excellent
        case 70...:    tier = .strong
        case 50...:    tier = .building
        default:       tier = .gettingStarted
        }

        return VisibilityResult(
            score: score,
            earned: earned,
            totalWeight: totalWeight,
            factors: factors,
            remaining: remaining,
            tier: tier
        )
    }
}
