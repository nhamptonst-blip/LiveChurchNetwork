import Foundation
import Combine

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var liveNowChurches: [Church] = []
    @Published var recommendedChurches: [Church] = []
    @Published var recentlyAdded: [Church] = []
    @Published var trendingChurches: [Church] = []
    @Published var newThisWeek: [Church] = []
    @Published var suggestedPeople: [DiscoverableUser] = []
    @Published var browseChurches: [Church] = []
    @Published var browsePeople: [DiscoverableUser] = []

    @Published var hasMoreChurches = true
    @Published var hasMorePeople = true
    @Published var isLoadingMore = false

    @Published var churchSearch = ""
    @Published var peopleSearch = ""
    @Published var selectedDenomination = "All"
    @Published var showLiveOnly = false
    @Published var churchSort: ChurchSort = .recommended
    @Published var activeFilters: Set<DiscoverFilter> = []

    @Published var followedChurchSlugs: Set<String> = []
    @Published var followedUserIds: Set<String> = []
    @Published var isCuratedLoading = true
    @Published var loadError = false

    enum ChurchSort: String, CaseIterable {
        case recommended = "Recommended"
        case recentlyAdded = "Recently Added"
        case alphabetical = "A–Z"
    }

    enum DiscoverFilter: Hashable {
        case liveNow
        case trending
        case nearMe
        case denomination(String)

        var displayName: String {
            switch self {
            case .liveNow: return "Live"
            case .trending: return "Trending"
            case .nearMe: return "Near Me"
            case .denomination(let denom): return denom
            }
        }
    }

    // MARK: - Computed Properties for Filtered Results

    var filteredBrowseChurches: [Church] {
        var result = browseChurches

        // Apply quick filters
        if activeFilters.contains(.liveNow) {
            result = result.filter { $0.isLive }
        }

        if activeFilters.contains(.trending) {
            result = result.filter { $0.followerCount > 500 }
        }

        // Filter by denomination if selected
        for filter in activeFilters {
            if case .denomination(let denom) = filter {
                result = result.filter { $0.denomination == denom }
                break
            }
        }

        return result
    }

    var mapViewChurches: [Church] {
        filteredBrowseChurches.filter { $0.hasAddress }
    }

    var denominationCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for church in browseChurches {
            counts[church.denomination, default: 0] += 1
        }
        return counts
    }

    // MARK: - Data Loading

    func loadInitialData(appState: AppState) async {
        loadError = false
        isCuratedLoading = true
        do {
            async let liveTask = SupabaseService.shared.getLiveNowChurches()
            async let recentTask = SupabaseService.shared.getRecentlyAddedChurches()
            async let browseTask = SupabaseService.shared.getApprovedChurchesPaged(offset: 0, limit: 20)
            async let peopleTask = SupabaseService.shared.getDiscoverableWorshippersPaged(offset: 0, limit: 20)

            let live = try await liveTask
            let recent = try await recentTask
            let browse = try await browseTask
            let people = try await peopleTask

            // Fetch profile photos for all churches
            let churchUserIds = (live + recent + browse).map { $0.userId }
            let profileMap = await fetchChurchPhotoMap(userIds: churchUserIds)

            liveNowChurches = live.map { toChurch($0, photoUrl: profileMap[$0.userId]) }
            recentlyAdded = recent.map { toChurch($0, photoUrl: profileMap[$0.userId]) }
            browseChurches = browse.map { toChurch($0, photoUrl: profileMap[$0.userId]) }
            browsePeople = people.map { toDiscoverableUser($0) }

            // Recommended is same as live for now (can be enhanced with RecommendationEngine later)
            recommendedChurches = liveNowChurches

            // Trending: use recentlyAdded or first few browse churches
            trendingChurches = recentlyAdded.count > 0 ? recentlyAdded : browseChurches.prefix(6).map { $0 }

            // New This Week: recentlyAdded churches
            newThisWeek = recentlyAdded

            // Load follow state
            if let userId = appState.currentUserId {
                let follows = (try? await SupabaseService.shared.getFollowing(followerId: userId)) ?? []
                followedChurchSlugs = Set(follows.filter { $0.followingType == "church" }.map { $0.followingId })
                followedUserIds = Set(follows.filter { $0.followingType == "worshipper" }.map { $0.followingId })
            }

            hasMorePeople = people.count >= 20
            hasMoreChurches = browse.count >= 20
        } catch {
            loadError = true
        }
        isCuratedLoading = false
    }

    func reload(appState: AppState) async {
        browseChurches = []
        browsePeople = []
        suggestedPeople = []
        liveNowChurches = []
        recentlyAdded = []
        hasMoreChurches = true
        hasMorePeople = true
        await loadInitialData(appState: appState)
    }

    func loadMoreChurches() async {
        guard hasMoreChurches && !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let offset = browseChurches.count
        let results = (try? await SupabaseService.shared.searchChurches(
            query: churchSearch.isEmpty ? nil : churchSearch,
            denomination: selectedDenomination == "All" ? nil : selectedDenomination,
            liveOnly: showLiveOnly,
            offset: offset,
            limit: 20
        )) ?? []

        if results.count < 20 {
            hasMoreChurches = false
        }

        // Fetch photos for new churches
        let userIds = results.map { $0.userId }
        let profileMap = await fetchChurchPhotoMap(userIds: userIds)

        let newChurches = results.map { toChurch($0, photoUrl: profileMap[$0.userId]) }
        browseChurches.append(contentsOf: newChurches)
    }

    func loadMorePeople() async {
        guard hasMorePeople && !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let offset = browsePeople.count
        let results = (try? await SupabaseService.shared.getDiscoverableWorshippersPaged(offset: offset, limit: 20)) ?? []

        if results.count < 20 {
            hasMorePeople = false
        }

        let newPeople = results.map { toDiscoverableUser($0) }
        browsePeople.append(contentsOf: newPeople)
    }

    func reloadChurchesWithFilters() async {
        browseChurches = []
        hasMoreChurches = true
        await loadMoreChurches()
    }

    // MARK: - Helpers

    private func fetchChurchPhotoMap(userIds: [UUID]) async -> [UUID: String] {
        let profiles = (try? await SupabaseService.shared.getProfiles(ids: userIds)) ?? []
        var map: [UUID: String] = [:]
        for profile in profiles {
            if let photoUrl = profile.photoUrl {
                map[profile.id] = photoUrl
            }
        }
        return map
    }

    private func toChurch(_ submission: ChurchSubmission, photoUrl: String?) -> Church {
        let name = submission.churchName ?? "Unknown Church"
        let addressParts = [
            submission.addressLine,
            [submission.city, submission.state, submission.postalCode]
                .compactMap { $0 }.joined(separator: ", ")
        ].compactMap { $0 }.joined(separator: ", ")

        var church = Church(
            name: name,
            slug: name.lowercased().replacingOccurrences(of: " ", with: "-"),
            image: photoUrl ?? "",
            denomination: submission.denomination ?? "",
            permalink: "",
            phone: submission.phone ?? "",
            website: submission.website ?? "",
            serviceTimes: submission.serviceTimes ?? "",
            about: submission.about ?? ""
        )
        church.address = addressParts
        church.isLive = submission.isLive
        church.city = submission.city ?? ""
        church.coverImage = photoUrl ?? ""
        church.pastorName = submission.pastorName ?? ""
        church.followerCount = 0
        church.livestreamUrl = submission.livestreamUrl ?? ""
        church.languages = submission.languages ?? ""
        church.ministries = submission.ministries ?? ""
        church.worshipStyle = submission.worshipStyle ?? ""
        church.latitude = submission.latitude
        church.longitude = submission.longitude
        return church
    }

    private func toDiscoverableUser(_ profile: Profile) -> DiscoverableUser {
        var user = DiscoverableUser(
            id: profile.id,
            name: profile.fullName ?? "Unknown",
            bio: profile.bio,
            denomination: profile.denomination,
            city: profile.city,
            photoUrl: profile.photoUrl,
            coverImageUrl: profile.coverUrl
        )
        user.homeChurchName = profile.homeChurchName
        user.isLeader = profile.isLeader ?? (profile.role == "church_admin")
        user.isDiscoverable = profile.isDiscoverable ?? true
        user.isSearchable = profile.isSearchable ?? true
        user.showHomeChurch = profile.showHomeChurch ?? true
        user.showFollowers = profile.showFollowers ?? true
        user.showFollowing = profile.showFollowing ?? true
        return user
    }
}
