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
            VStack(spacing: 0) {
                sectionToggle
                Divider()
                Group {
                    if section == .churches { churchesContent }
                    else                   { peopleContent }
                }
            }
            .background(Color.lcCream)
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await loadDiscoverContent() }
    }

    // MARK: - Segmented toggle

    private var sectionToggle: some View {
        HStack(spacing: 0) {
            ForEach(DiscoverSection.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { section = tab }
                } label: {
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: tab == .churches ? "building.2.fill" : "person.2.fill")
                                .font(.system(size: 13))
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: section == tab ? .bold : .regular))
                        }
                        .foregroundColor(section == tab ? .lcNavy : .lcText3)
                        .padding(.vertical, 12)
                        Rectangle()
                            .fill(section == tab ? Color.lcNavy : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
            }
        }
    }

    // MARK: - Churches content

    private var churchesContent: some View {
        VStack(spacing: 0) {
            churchSearchBar
            filterRow

            if filteredChurches.isEmpty {
                churchEmptyState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Suggested carousel — hidden when the user is actively searching/filtering
                        if churchSearch.isEmpty && selectedDenomination == "All"
                            && !showLiveOnly && !suggestedChurches.isEmpty {
                            suggestedChurchesSection
                        }
                        churchResultsHeader
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 14),
                                      GridItem(.flexible(), spacing: 14)],
                            spacing: 14
                        ) {
                            ForEach(filteredChurches) { church in
                                ChurchCard(church: church)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
    }

    // MARK: - Suggested churches carousel

    private var suggestedChurchesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Suggested for You")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.lcText2)
                Spacer()
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestedChurches.prefix(6)) { church in
                        NavigationLink(destination: ChurchDetailView(church: church)) {
                            SuggestedChurchCard(church: church)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 14)
    }

    private var churchSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(.lcText3)
            TextField("Search churches, denominations...", text: $churchSearch)
                .font(.system(size: 15))
                .foregroundColor(.lcText)
            if !churchSearch.isEmpty {
                Button { churchSearch = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.lcText3)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button { showLiveOnly.toggle() } label: {
                    HStack(spacing: 5) {
                        if showLiveOnly { Circle().fill(Color.red).frame(width: 6, height: 6) }
                        Text("Live Now").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(showLiveOnly ? .white : .red)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(showLiveOnly ? Color.red : Color.red.opacity(0.08))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(showLiveOnly ? Color.clear : Color.red.opacity(0.3), lineWidth: 1))
                }
                ForEach(denominations, id: \.self) { denom in
                    Button {
                        withAnimation(.easeInOut(duration: 0.14)) { selectedDenomination = denom }
                    } label: {
                        Text(denom)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(selectedDenomination == denom ? .white : .lcNavy)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(selectedDenomination == denom
                                        ? Color.lcNavy : Color.lcNavy.opacity(0.06))
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
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
                        .font(.system(size: 40)).foregroundColor(.lcText3)
                    Text("No users found")
                        .font(.system(size: 16, weight: .bold)).foregroundColor(.lcText)
                    Text("Try a different search term.")
                        .font(.system(size: 13)).foregroundColor(.lcText3)
                    Spacer()
                }
            } else if !peopleSearch.isEmpty {
                // Active search — plain results, no suggested section
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPeople) { user in
                            NavigationLink(destination: UserProfileView(userId: user.id)) {
                                UserDiscoveryCard(user: user)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            } else {
                // Browsing — top 5 as "Suggested", rest under "More Worshippers"
                ScrollView {
                    LazyVStack(spacing: 12) {
                        sectionLabel("Suggested for You")
                        ForEach(Array(rankedPeople.prefix(5))) { user in
                            NavigationLink(destination: UserProfileView(userId: user.id)) {
                                UserDiscoveryCard(user: user)
                            }
                            .buttonStyle(.plain)
                        }

                        if rankedPeople.count > 5 {
                            Rectangle()
                                .fill(Color.lcBorder)
                                .frame(height: 1)
                                .padding(.vertical, 6)
                            sectionLabel("More Worshippers")
                            ForEach(Array(rankedPeople.dropFirst(5))) { user in
                                NavigationLink(destination: UserProfileView(userId: user.id)) {
                                    UserDiscoveryCard(user: user)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var peopleSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(.lcText3)
            TextField("Search people...", text: $peopleSearch)
                .font(.system(size: 15))
                .foregroundColor(.lcText)
            if !peopleSearch.isEmpty {
                Button { peopleSearch = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.lcText3)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.lcText2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    // MARK: - Load

    private func toChurch(_ submission: ChurchSubmission) -> Church {
        let slug = (submission.churchName ?? "").lowercased().replacingOccurrences(of: " ", with: "-")
        return Church(
            name: submission.churchName ?? "",
            slug: slug,
            image: "",
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

        // Convert ChurchSubmission records to Church structs
        churches = approved.map { toChurch($0) }

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

// MARK: - User Discovery Card

struct UserDiscoveryCard: View {
    let user: DiscoverableUser
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            UserAvatarView(user: user, size: .medium)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.lcText)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let denom = user.denomination, !denom.isEmpty {
                        Text(denom)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.lcNavy)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Color.lcNavy.opacity(0.08))
                            .cornerRadius(20)
                    }
                    if user.followerCount > 0 {
                        Text("\(user.followerCount) followers")
                            .font(.system(size: 11))
                            .foregroundColor(.lcText3)
                    }
                }

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            // Follow button (real users only)
            if !appState.isGuest, appState.currentUserId != nil {
                FollowButton(
                    followingId: user.id.uuidString,
                    followingType: "worshipper"
                )
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
