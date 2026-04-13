import Foundation

// MARK: - Recommendation Engine
//
// Pure, stateless scoring logic for Discover recommendations.
// Accepts caller-supplied signals so it works identically for real Supabase
// data and mock seed data — no coupling to either source.
//
// Signals and weights:
//   Church overlap   +4 / +10 / +16   (strongest — shared interest is most telling)
//   Denomination     +2 – +4          (same tradition or adjacent)
//   City / metro     +1 – +5          (same city, metro cluster, or same state)
//   Mutual follows   +3 per mutual    (social graph proximity)
//   Hub score        +1 – +3          (platform discoverability)

enum RecommendationEngine {

    // MARK: - Viewer

    /// Everything known about the person browsing Discover.
    struct Viewer {
        var denomination: String?
        var city:         String?
        var churchSlugs:  Set<String>   // slugs of churches they follow
        var followedIds:  Set<String>   // UUID strings of worshippers they follow

        /// True when we have no personal signals → recommendations fall back to popularity.
        var hasSignals: Bool {
            denomination != nil || city != nil || !churchSlugs.isEmpty || !followedIds.isEmpty
        }
    }

    // MARK: - User recommendations

    /// Returns all `candidates` sorted by relevance to `viewer`.
    /// Users the viewer already follows and the viewer themselves are excluded.
    static func suggestedUsers(
        for viewer: Viewer,
        from candidates: [DiscoverableUser],
        followGraph: [UUID: [UUID]] = [:]
    ) -> [DiscoverableUser] {

        // Precompute: for each candidate UUID, which other UUIDs follow them.
        // Used to find mutual connections in O(1) per candidate.
        var followersOf: [UUID: Set<String>] = [:]
        for (followerId, followedList) in followGraph {
            for followedId in followedList {
                followersOf[followedId, default: []].insert(followerId.uuidString)
            }
        }

        func score(_ u: DiscoverableUser) -> Int {
            var s = 0

            // 1. Shared church follows — highest-weight signal
            let shared = Set(u.churchSlugs).intersection(viewer.churchSlugs).count
            switch shared {
            case 1: s += 4
            case 2: s += 10
            default: if shared >= 3 { s += 16 }
            }

            // 2. Denomination affinity
            if let d = u.denomination, let mine = viewer.denomination {
                s += (d == mine) ? 4 : adjacentDenomScore(d, mine)
            }

            // 3. City / metro proximity
            s += cityScore(u.city, viewer.city)

            // 4. Mutual connections (people viewer follows who also follow this user)
            let theirFollowers = followersOf[u.id] ?? []
            let mutuals = theirFollowers.intersection(viewer.followedIds)
            s += mutuals.count * 3

            // 5. Platform discoverability (follower count tier)
            s += hubScore(u.followerCount)

            return s
        }

        let excluded = viewer.followedIds
        return candidates
            .filter { !excluded.contains($0.id.uuidString) }
            .map    { ($0, score($0)) }
            .sorted { l, r in l.1 != r.1 ? l.1 > r.1 : l.0.name < r.0.name }
            .map    { $0.0 }
    }

    // MARK: - Church recommendations

    /// Returns churches from `candidates` sorted by relevance to `viewer`.
    /// Churches the viewer already follows are excluded.
    static func suggestedChurches(
        for viewer: Viewer,
        from candidates: [Church],
        seedUsers: [DiscoverableUser] = [],
        followGraph: [UUID: [UUID]] = [:]
    ) -> [Church] {

        // Social proof: count how many followed users follow each church slug.
        // When viewer has no follows yet, uses overall seed popularity as fallback.
        var socialCount: [String: Int] = [:]
        let usingSeedFallback = viewer.followedIds.isEmpty
        let sources = usingSeedFallback
            ? seedUsers
            : seedUsers.filter { viewer.followedIds.contains($0.id.uuidString) }
        for user in sources {
            for slug in user.churchSlugs {
                socialCount[slug, default: 0] += 1
            }
        }
        let socialWeight = usingSeedFallback ? 1 : 4

        func score(_ church: Church) -> Int {
            var s = 0

            // 1. Social proof (followed by people you follow, or popular overall)
            s += (socialCount[church.slug] ?? 0) * socialWeight

            // 2. Denomination match
            if !church.denomination.isEmpty, let mine = viewer.denomination {
                s += (church.denomination == mine) ? 5 : adjacentDenomScore(church.denomination, mine)
            }

            // 3. Currently live — strong recency signal
            if church.isLive { s += 4 }

            // 4. Stable popularity proxy (deterministic, not random)
            s += abs(church.slug.hashValue) % 3

            return s
        }

        return candidates
            .filter { !viewer.churchSlugs.contains($0.slug) }
            .map    { ($0, score($0)) }
            .sorted { l, r in l.1 != r.1 ? l.1 > r.1 : l.0.name < r.0.name }
            .map    { $0.0 }
    }

    // MARK: - Private helpers

    static func adjacentDenomScore(_ a: String, _ b: String) -> Int {
        let evangelical = Set(["Baptist", "AME", "Pentecostal", "Non-Denominational"])
        let mainline    = Set(["Methodist", "Presbyterian", "Lutheran", "Episcopal", "AME"])
        let liturgical  = Set(["Catholic", "Orthodox", "Episcopal"])
        var score = 0
        if evangelical.contains(a) && evangelical.contains(b) { score = max(score, 2) }
        if mainline.contains(a)    && mainline.contains(b)    { score = max(score, 2) }
        if liturgical.contains(a)  && liturgical.contains(b)  { score = max(score, 1) }
        return score
    }

    static func cityScore(_ a: String?, _ b: String?) -> Int {
        guard let a = a, let b = b, !a.isEmpty, !b.isEmpty else { return 0 }
        let cityA  = a.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? a
        let cityB  = b.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? b
        let stateA = a.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? ""
        let stateB = b.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? ""
        if cityA == cityB { return 5 }
        let dcMetro   = Set(["Silver Spring", "Washington", "Baltimore"])
        let southeast = Set(["Atlanta", "Charlotte", "Richmond", "Nashville"])
        if dcMetro.contains(cityA)   && dcMetro.contains(cityB)   { return 3 }
        if southeast.contains(cityA) && southeast.contains(cityB) { return 2 }
        if !stateA.isEmpty && stateA == stateB                    { return 1 }
        return 0
    }

    static func hubScore(_ followerCount: Int) -> Int {
        switch followerCount {
        case 1500...: return 3
        case 800...:  return 2
        case 400...:  return 1
        default:      return 0
        }
    }
}
