import SwiftUI

// MARK: - Discover tab toggle

private enum DiscoverSection: String, CaseIterable {
    case churches = "Churches"
    case people   = "People"
}

// MARK: - Discover View

struct DirectoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var section: DiscoverSection = .churches
    @State private var isLoading = true

    // ── Church state ────────────────────────────────────────────────────
    @State private var churchSearch        = ""
    @State private var selectedDenomination = "All"
    @State private var showLiveOnly        = false
    @State private var liveChurchNames: Set<String> = []

    // ── People state ────────────────────────────────────────────────────
    @State private var peopleSearch = ""

    // ── Recommendation state ────────────────────────────────────────────
    @State private var followedChurchSlugs: Set<String> = Set(MockDataProvider.followedChurchSlugs)
    @State private var followedUserIds:     Set<String> = []
    @State private var suggestedPeople:     [DiscoverableUser] = []
    @State private var suggestedChurches:   [Church] = []

    // ── Dynamic churches from Supabase ────────────────────────────────
    @State private var churches: [Church] = []

    // ── Dynamic members from Supabase ────────────────────────────────
    @State private var discoveredMembers: [DiscoverableUser] = []


    private let denominations: [String] = [
        "All", "Non-Denominational", "Baptist", "Catholic", "Methodist",
        "Pentecostal", "Orthodox", "Presbyterian", "Lutheran", "Evangelical",
        "Episcopal", "Anglican", "Reformed", "Church of Christ",
        "Assemblies of God", "Seventh-day Adventist",
        "African Methodist Episcopal (AME)", "Other"
    ]

    /// Denominations with explicit chips (excludes "All" and "Other").
    private let namedDenominations: [String] = [
        "Non-Denominational", "Baptist", "Catholic", "Methodist",
        "Pentecostal", "Orthodox", "Presbyterian", "Lutheran", "Evangelical",
        "Episcopal", "Anglican", "Reformed", "Church of Christ",
        "Assemblies of God", "Seventh-day Adventist",
        "African Methodist Episcopal (AME)"
    ]

    // ── Filtered / ranked data ──────────────────────────────────────────

    private var filteredChurches: [Church] {
        churches.filter { church in
            let matchesSearch = churchSearch.isEmpty
                || church.name.localizedCaseInsensitiveContains(churchSearch)
                || church.denomination.localizedCaseInsensitiveContains(churchSearch)
                || church.about.localizedCaseInsensitiveContains(churchSearch)
            let matchesDenom: Bool
            switch selectedDenomination {
            case "All":
                matchesDenom = true
            case "Other":
                // Matches empty denomination, literal "Other", or any value not in namedDenominations
                matchesDenom = church.denomination.isEmpty
                    || church.denomination.caseInsensitiveCompare("Other") == .orderedSame
                    || !namedDenominations.contains(where: {
                        $0.caseInsensitiveCompare(church.denomination) == .orderedSame
                    })
            default:
                matchesDenom = church.denomination
                    .caseInsensitiveCompare(selectedDenomination) == .orderedSame
            }
            let matchesLive = !showLiveOnly || liveChurchNames.contains(church.name.lowercased())
            return matchesSearch && matchesDenom && matchesLive
        }
    }

    /// People list ranked by relevance; filtered by search term when active.
    private var rankedPeople: [DiscoverableUser] {
        suggestedPeople.isEmpty ? discoveredMembers : suggestedPeople
    }

    private var filteredPeople: [DiscoverableUser] {
        guard !peopleSearch.isEmpty else { return rankedPeople }
        return rankedPeople.filter {
            $0.name.localizedCaseInsensitiveContains(peopleSearch)
            || ($0.denomination ?? "").localizedCaseInsensitiveContains(peopleSearch)
            || ($0.city ?? "").localizedCaseInsensitiveContains(peopleSearch)
        }
    }

    // ── Body ────────────────────────────────────────────────────────────

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.98, green: 0.98, blue: 0.97).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Discover")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.lcText)
                        Text("Find churches, people, and live services")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                    // Segmented tabs
                    sectionToggle
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)

                    // Content
                    Group {
                        if section == .churches { churchesContent }
                        else                   { peopleContent }
                    }
                    .animation(.appStandard, value: section)
                    .id(section)
                }
            }
        }
        .task { await loadDiscoverContent() }
    }

    // MARK: - Segmented toggle (Pill style)

    private var sectionToggle: some View {
        HStack(spacing: 8) {
            ForEach(DiscoverSection.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.appSpring) { section = tab }
                    HapticEngine.selection()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab == .churches ? "building.2.fill" : "person.2.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(section == tab ? .white : .lcText2)
                    .padding(.vertical, 10)
                    .background(section == tab ? Color.lcNavy : Color.white)
                    .cornerRadius(12)
                    .shadow(color: section == tab ? Color.lcNavy.opacity(0.2) : Color.clear, radius: 6, x: 0, y: 2)
                }
            }
            Spacer()
        }
    }

    // MARK: - Churches content

    private var churchesContent: some View {
        VStack(spacing: 0) {
            churchSearchBar
            filterRow

            if isLoading {
                ScrollView {
                    VStack(spacing: 16) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(0..<6, id: \.self) { _ in
                                ChurchCardSkeleton()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            } else if filteredChurches.isEmpty {
                churchEmptyState
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Suggested section — hidden when the user is actively searching/filtering
                        if churchSearch.isEmpty && selectedDenomination == "All"
                            && !showLiveOnly && !suggestedChurches.isEmpty {
                            suggestedChurchesSection
                        }

                        // Results header
                        if !suggestedChurches.isEmpty && churchSearch.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Divider().padding(.bottom, 16)
                                Text("All Churches")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.lcText)
                            }
                            .padding(.horizontal, 20)
                        }

                        // Church grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(filteredChurches, id: \.slug) { church in
                                ZStack(alignment: .topTrailing) {
                                    NavigationLink(destination: ChurchDetailView(church: church)) {
                                        ChurchCard(church: church)
                                    }
                                    .buttonStyle(.plain)

                                    // Follow button overlay - positioned separately
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Button(action: {
                                                Task {
                                                    await toggleChurchFollow(church: church)
                                                }
                                            }) {
                                                Text(followedChurchSlugs.contains(church.slug) ? "Following" : "Follow")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(followedChurchSlugs.contains(church.slug) ? .lcNavy : .white)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(followedChurchSlugs.contains(church.slug) ? Color.white : Color.lcNavy)
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.lcNavy, lineWidth: followedChurchSlugs.contains(church.slug) ? 1.5 : 0)
                                                    )
                                            }
                                            .padding(12)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.97))
    }

    // MARK: - Suggested churches section

    private var suggestedChurchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested for You")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.lcText)
                .padding(.horizontal, 20)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(suggestedChurches.prefix(4), id: \.slug) { church in
                    ZStack(alignment: .topTrailing) {
                        NavigationLink(destination: ChurchDetailView(church: church)) {
                            ChurchCard(church: church)
                        }
                        .buttonStyle(.plain)

                        // Follow button overlay - positioned separately
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    Task {
                                        await toggleChurchFollow(church: church)
                                    }
                                }) {
                                    Text(followedChurchSlugs.contains(church.slug) ? "Following" : "Follow")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(followedChurchSlugs.contains(church.slug) ? .lcNavy : .white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(followedChurchSlugs.contains(church.slug) ? Color.white : Color.lcNavy)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.lcNavy, lineWidth: followedChurchSlugs.contains(church.slug) ? 1.5 : 0)
                                        )
                                }
                                .padding(12)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var churchSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.lcText3)

            TextField("Search churches...", text: $churchSearch)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.lcText)

            if !churchSearch.isEmpty {
                Button { churchSearch = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.lcText3)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var filterRow: some View {
        HStack(spacing: 10) {
            // Live Now button
            Button {
                withAnimation(.appSpring) { showLiveOnly.toggle() }
                HapticEngine.selection()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showLiveOnly ? "dot.radiowaves.right" : "dot.circle")
                        .font(.system(size: 13, weight: .bold))
                    Text("Live Now")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(showLiveOnly ? .white : .red)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(showLiveOnly ? Color.red : Color.red.opacity(0.1))
                .cornerRadius(12)
                .shadow(color: showLiveOnly ? Color.red.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
            }

            // Denomination picker
            Menu {
                ForEach(denominations, id: \.self) { denom in
                    Button {
                        withAnimation(.appSpring) { selectedDenomination = denom }
                        HapticEngine.selection()
                    } label: {
                        HStack {
                            Text(denom)
                            if selectedDenomination == denom {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedDenomination)
                        .font(.system(size: 13, weight: .bold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(selectedDenomination == "All" ? .lcNavy : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(selectedDenomination == "All" ? Color.white : Color.lcNavy)
                .cornerRadius(12)
                .shadow(color: selectedDenomination == "All" ? Color.clear : Color.lcNavy.opacity(0.2), radius: 4, x: 0, y: 2)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var churchResultsHeader: some View {
        HStack {
            Text("\(filteredChurches.count) church\(filteredChurches.count == 1 ? "" : "es")")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.lcText2)
            if showLiveOnly {
                Text("• Live Now").font(.system(size: 12, weight: .semibold)).foregroundColor(.red)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var churchEmptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: showLiveOnly ? "antenna.radiowaves.left.and.right" : "building.2")
                .font(.system(size: 40)).foregroundColor(.lcText3)
            Text(showLiveOnly ? "No churches live right now" : "No churches found")
                .font(.system(size: 16, weight: .bold)).foregroundColor(.lcText)
            Text(showLiveOnly
                 ? "Check back soon or turn off the Live Now filter."
                 : "Try a different search or filter.")
                .font(.system(size: 13)).foregroundColor(.lcText3)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - People content

    private var peopleContent: some View {
        VStack(spacing: 0) {
            peopleSearchBar

            if filteredPeople.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.2")
                        .font(.system(size: 48))
                        .foregroundColor(.lcText3)
                    Text("No people found")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.lcText)
                    Text("Try a different search or discover featured worshippers.")
                        .font(.system(size: 13))
                        .foregroundColor(.lcText3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.98, green: 0.98, blue: 0.97))
            } else if !peopleSearch.isEmpty {
                // Active search — plain results, no suggested section
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(filteredPeople) { user in
                            NavigationLink(destination: UserProfileView(userId: user.id)) {
                                PeopleDiscoveryCard(user: user)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
                .background(Color(red: 0.98, green: 0.98, blue: 0.97))
            } else {
                // Browsing — suggested + more worshippers
                ScrollView {
                    VStack(spacing: 24) {
                        // Suggested section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Suggested for You")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.lcText)
                                .padding(.horizontal, 12)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                ForEach(Array(rankedPeople.prefix(5))) { user in
                                    NavigationLink(destination: UserProfileView(userId: user.id)) {
                                        PeopleDiscoveryCard(user: user)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 12)
                        }

                        // More worshippers section
                        if rankedPeople.count > 5 {
                            VStack(alignment: .leading, spacing: 14) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Divider().padding(.bottom, 14)
                                    Text("More Worshippers")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.lcText)
                                }
                                .padding(.horizontal, 12)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                    ForEach(Array(rankedPeople.dropFirst(5))) { user in
                                        NavigationLink(destination: UserProfileView(userId: user.id)) {
                                            PeopleDiscoveryCard(user: user)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.horizontal, 0)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
                .background(Color(red: 0.98, green: 0.98, blue: 0.97))
            }
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.97))
    }

    private var peopleSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.lcText3)

            TextField("Search people...", text: $peopleSearch)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.lcText)

            if !peopleSearch.isEmpty {
                Button { peopleSearch = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.lcText3)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.lcText2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    // MARK: - Load

    private func toChurch(_ submission: ChurchSubmission, photoUrl: String?) -> Church {
        let slug = (submission.churchName ?? "").lowercased().replacingOccurrences(of: " ", with: "-")
        return Church(
            name: submission.churchName ?? "",
            slug: slug,
            image: photoUrl ?? "",
            denomination: submission.denomination ?? "",
            permalink: "",
            phone: submission.phone ?? "",
            website: submission.website ?? "",
            serviceTimes: submission.serviceTimes ?? "",
            about: submission.about ?? "",
            isLive: submission.isLive
        )
    }

    private func toDiscoverableUser(_ profile: Profile) -> DiscoverableUser {
        return DiscoverableUser(
            id: profile.id,
            name: profile.fullName ?? "User",
            bio: profile.bio,
            denomination: profile.denomination,
            city: profile.city,
            photoUrl: profile.photoUrl,
            coverImageUrl: profile.coverUrl,
            activityPrivacy: profile.activityPrivacy,
            followersPrivacy: profile.followersPrivacy,
            followingPrivacy: profile.followingPrivacy,
            churchesPrivacy: profile.churchesPrivacy
        )
    }

    private func loadDiscoverContent() async {
        // ── 1. Fetch approved churches and discoverable members from Supabase ────
        async let approvedTask = SupabaseService.shared.getApprovedChurches()
        async let liveTask = SupabaseService.shared.getLiveChurches()
        async let membersTask = SupabaseService.shared.getDiscoverableWorshippers()

        let approved = (try? await approvedTask) ?? []
        let live = (try? await liveTask) ?? []
        let members = (try? await membersTask) ?? []

        // Fetch church user profiles to get logos (photo_url)
        let churchUserIds = approved.map { $0.userId }
        let churchProfiles = (try? await SupabaseService.shared.getProfiles(ids: churchUserIds)) ?? []

        // Build a map of userId → photo_url for quick lookup
        var churchPhotoMap: [UUID: String] = [:]
        for profile in churchProfiles {
            if let photoUrl = profile.photoUrl {
                churchPhotoMap[profile.id] = photoUrl
            }
        }

        // Convert ChurchSubmission records to Church structs, adding profile photos
        churches = approved.map { toChurch($0, photoUrl: churchPhotoMap[$0.userId]) }

        // Convert Profile records to DiscoverableUser structs
        discoveredMembers = members.map { toDiscoverableUser($0) }

        // ── 2. Live churches (for the "Live Now" filter chip) ───────────
        liveChurchNames = Set(live.compactMap { $0.churchName?.lowercased() })

        // ── 3. Current user's follows → viewer signals ──────────────────
        if let userId = appState.currentUserId {
            let follows = (try? await SupabaseService.shared.getFollowing(followerId: userId)) ?? []
            let realSlugs = Set(follows.filter { $0.followingType == "church"     }.map { $0.followingId })
            let realIds   = Set(follows.filter { $0.followingType == "worshipper" }.map { $0.followingId })
            if !realSlugs.isEmpty { followedChurchSlugs = realSlugs }
            if !realIds.isEmpty   { followedUserIds     = realIds }
        }

        // ── 4. Build viewer and score recommendations ────────────────────
        let viewer = RecommendationEngine.Viewer(
            denomination: appState.profile?.denomination,
            city:         appState.profile?.city,
            churchSlugs:  followedChurchSlugs,
            followedIds:  followedUserIds
        )

        let graph = MockDataProvider.followGraph

        suggestedPeople = RecommendationEngine.suggestedUsers(
            for: viewer, from: discoveredMembers, followGraph: graph
        )

        // Score suggestions from the dynamic churches list
        suggestedChurches = Array(
            RecommendationEngine.suggestedChurches(
                for: viewer, from: churches, seedUsers: discoveredMembers, followGraph: graph
            ).prefix(8)
        )

        isLoading = false
    }

    private func toggleChurchFollow(church: Church) async {
        guard let currentUserId = appState.currentUserId else { return }

        let isCurrentlyFollowing = followedChurchSlugs.contains(church.slug)

        do {
            if isCurrentlyFollowing {
                HapticEngine.impact(.light)
                try await SupabaseService.shared.unfollow(followerId: currentUserId, followingId: church.slug)
                _ = await MainActor.run {
                    followedChurchSlugs.remove(church.slug)
                }
            } else {
                HapticEngine.impact(.medium)
                try await SupabaseService.shared.follow(followerId: currentUserId, followingId: church.slug, followingType: "church")
                _ = await MainActor.run {
                    followedChurchSlugs.insert(church.slug)
                }
            }
        } catch {
            print("Error toggling follow for church \(church.name): \(error)")
        }
    }
}

// MARK: - Suggested Church Card (horizontal carousel)

struct SuggestedChurchCard: View {
    let church: Church

    private var churchInitial: String {
        String(church.name.prefix(1)).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            Group {
                if !church.image.isEmpty, let url = URL(string: church.image) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            churchInitialCircle
                        }
                    }
                } else {
                    churchInitialCircle
                }
            }
            .frame(width: 162, height: 96)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Text(church.name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.lcText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if church.isLive { LiveBadge() }
                }
                if !church.denomination.isEmpty {
                    Text(church.denomination)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.lcNavy)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Color.lcNavy.opacity(0.08))
                        .cornerRadius(20)
                        .lineLimit(1)
                }
            }
            .padding(10)
            .frame(width: 162, alignment: .leading)
        }
        .frame(width: 162)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private var churchInitialCircle: some View {
        ZStack {
            Circle()
                .fill(Color.lcNavy.opacity(0.12))
            Text(churchInitial)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.lcNavy)
        }
    }
}

// MARK: - Church Card Skeleton (Loading State)

struct ChurchCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.lcBorder.opacity(0.3))
                .frame(height: 140)
                .shimmer(isAnimating: isAnimating)

            // Info section skeleton
            VStack(alignment: .leading, spacing: 8) {
                // Title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.lcBorder.opacity(0.3))
                    .frame(height: 12)
                    .shimmer(isAnimating: isAnimating)

                // Denomination badge skeleton
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.lcBorder.opacity(0.3))
                    .frame(width: 60, height: 20)
                    .shimmer(isAnimating: isAnimating)
            }
            .padding(12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Shimmer Modifier (for skeleton)

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
    }
}
