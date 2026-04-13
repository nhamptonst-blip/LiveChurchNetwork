import SwiftUI

// MARK: - Tabs

private enum UserProfileTab: String, CaseIterable {
    case posts    = "Posts"
    case about    = "About"
    case churches = "Churches"
    case activity = "Activity"
}

// MARK: - User Profile View (loading shell)
//
// Accepts a userId, resolves full user data from MockDataProvider or Supabase,
// then renders UserProfileContentView with the complete DiscoverableUser.
// Navigation destinations: Discover → People, Feed author tap, Notifications new_follower.

struct UserProfileView: View {
    let userId: UUID
    @EnvironmentObject var appState: AppState
    @State private var resolvedUser: DiscoverableUser?
    @State private var isLoadingProfile = true
    @State private var viewerFollowsUser = false

    var body: some View {
        Group {
            if isLoadingProfile {
                ProgressView()
                    .tint(.lcNavy)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let user = resolvedUser {
                UserProfileContentView(user: user, viewerFollows: viewerFollowsUser)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 38))
                        .foregroundColor(.lcText3)
                        .padding(.top, 60)
                    Text("User not found")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.lcText)
                    Text("This profile could not be loaded.")
                        .font(.system(size: 13))
                        .foregroundColor(.lcText3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.lcCream)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadUser() }
    }

    private func loadUser() async {
        print("[UserProfileView] Loading userId: \(userId)")

        // 1. Seed / mock data lookup — instant, no network
        if let seed = MockDataProvider.allSeedUsers.first(where: { $0.id == userId }) {
            print("[UserProfileView] Found seed user: \(seed.name)")
            await MainActor.run {
                resolvedUser = seed
                isLoadingProfile = false
            }
            return
        }

        // 2. Supabase lookup for real accounts
        print("[UserProfileView] Not in seed data — fetching from Supabase for \(userId)")
        do {
            if let profile = try await SupabaseService.shared.getProfile(userId: userId) {
                var user = DiscoverableUser(
                    id: userId,
                    name: profile.fullName ?? "Unknown",
                    bio: profile.bio,
                    denomination: profile.denomination,
                    city: profile.city,
                    photoUrl: profile.photoUrl,
                    coverImageUrl: profile.coverUrl
                )
                // Map privacy settings from the fetched profile.
                user.activityPrivacy  = profile.activityPrivacy
                user.followersPrivacy = profile.followersPrivacy
                user.followingPrivacy = profile.followingPrivacy
                user.churchesPrivacy  = profile.churchesPrivacy
                print("[UserProfileView] Fetched from Supabase: \(user.name)")

                // Check if the current viewer already follows this user.
                if let viewerId = appState.currentUserId, viewerId != userId {
                    viewerFollowsUser = (try? await SupabaseService.shared.isFollowingUser(
                        followerId: viewerId, subjectId: userId)) ?? false
                }

                await MainActor.run { resolvedUser = user }
            } else {
                print("[UserProfileView] No profile found in Supabase for \(userId)")
            }
        } catch {
            print("[UserProfileView] Supabase fetch failed: \(error)")
        }
        await MainActor.run { isLoadingProfile = false }
    }
}

// MARK: - User Profile Content View

private struct UserProfileContentView: View {
    let user: DiscoverableUser
    let viewerFollows: Bool
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: UserProfileTab = .posts
    @State private var userPosts: [Post] = []
    @State private var isLoadingPosts = false

    // Follow list state
    @State private var followerEntries:  [FollowEntry] = []
    @State private var followingEntries: [FollowEntry] = []
    @State private var profileChurches:  [Church] = []
    @State private var showFollowersSheet  = false
    @State private var showFollowingSheet  = false
    @State private var showChurchesSheet   = false

    // MARK: - Derived

    private var isOwnProfile: Bool { appState.currentUserId == user.id }

    // V1 privacy: public = anyone, private = owner only
    private func canView(_ privacy: PrivacySetting) -> Bool {
        isOwnProfile || privacy == .public
    }

    /// Activity feed built from loaded data.
    private var activityItems: [ActivityEntry] {
        var items: [ActivityEntry] = []
        items.append(ActivityEntry(icon: "person.badge.plus", color: .lcNavy,
                                   text: "Joined Live Church Network", sub: nil))
        for church in profileChurches {
            items.append(ActivityEntry(icon: "building.2.fill", color: .lcGold,
                                       text: "Followed \(church.name)",
                                       sub: church.denomination.isEmpty ? nil : church.denomination))
        }
        if !followingEntries.isEmpty {
            let n = followingEntries.count
            items.append(ActivityEntry(icon: "person.fill.badge.plus", color: .lcTeal,
                                       text: "Following \(n) worshipper\(n == 1 ? "" : "s")", sub: nil))
        }
        return items
    }

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                statsStrip
                tabBar.background(Color.white)
                Rectangle().fill(Color.lcBorder).frame(height: 1)
                tabContent.padding(.bottom, 48)
            }
        }
        .background(Color.lcCream)
        .task {
            await loadPosts()
            await loadFollowData()
        }
        .sheet(isPresented: $showFollowersSheet) {
            FollowListSheet(title: "Followers", entries: followerEntries)
        }
        .sheet(isPresented: $showFollowingSheet) {
            FollowListSheet(title: "Following", entries: followingEntries)
        }
        .sheet(isPresented: $showChurchesSheet) {
            ChurchListSheet(churches: profileChurches)
        }
    }

    // MARK: - Load follow data

    private func loadFollowData() async {
        // Seed users: use MockDataProvider as source of truth for follow graph
        if MockDataProvider.allSeedUsers.contains(where: { $0.id == user.id }) {
            let seedFollowerIds = MockDataProvider.followGraph
                .filter { $0.value.contains(user.id) }.map { $0.key }
            followerEntries = seedFollowerIds.map { resolveEntry(id: $0, profileMap: [:]) }

            let seedFollowingIds = MockDataProvider.followGraph[user.id] ?? []
            followingEntries = seedFollowingIds.map { resolveEntry(id: $0, profileMap: [:]) }

            let slugs = Set(user.churchSlugs)
                .union(MockDataProvider.churchFollowGraph[user.id].map(Set.init) ?? [])
            profileChurches = appState.churches(bySlugs: slugs)
            return
        }

        // Real Supabase user
        async let followersTask = SupabaseService.shared.getFollowers(userId: user.id)
        async let followingTask = SupabaseService.shared.getFollowing(followerId: user.id)

        let rawFollowers = (try? await followersTask) ?? []
        let rawFollowing = (try? await followingTask) ?? []

        let followerIds  = rawFollowers.map { $0.followerId }
        let followingIds = rawFollowing.filter { $0.followingType == "worshipper" }
                                       .compactMap { UUID(uuidString: $0.followingId) }
        let churchSlugs  = Set(rawFollowing.filter { $0.followingType == "church" }.map { $0.followingId })
                          .union(user.churchSlugs)

        async let fProfiles = SupabaseService.shared.getProfiles(ids: followerIds)
        async let gProfiles = SupabaseService.shared.getProfiles(ids: followingIds)

        let fMap = Dictionary(uniqueKeysWithValues: ((try? await fProfiles) ?? []).map { ($0.id, $0) })
        let gMap = Dictionary(uniqueKeysWithValues: ((try? await gProfiles) ?? []).map { ($0.id, $0) })

        followerEntries  = followerIds.map  { resolveEntry(id: $0, profileMap: fMap) }
        followingEntries = followingIds.map { resolveEntry(id: $0, profileMap: gMap) }
        profileChurches  = appState.churches(bySlugs: churchSlugs)

        print("[UserProfile] followers:\(followerEntries.count) following:\(followingEntries.count) churches:\(profileChurches.count)")
    }

    private func resolveEntry(id: UUID, profileMap: [UUID: Profile]) -> FollowEntry {
        if let p = profileMap[id] {
            return FollowEntry(id: id, displayName: p.fullName ?? "LCN Member",
                               photoUrl: p.photoUrl, subtitle: p.denomination ?? p.city)
        }
        if let seed = MockDataProvider.allSeedUsers.first(where: { $0.id == id }) {
            return FollowEntry(id: id, displayName: seed.name,
                               photoUrl: seed.photoUrl, subtitle: seed.denomination ?? seed.city)
        }
        return FollowEntry(id: id, displayName: "LCN Member", photoUrl: nil, subtitle: nil)
    }

    private func loadPosts() async {
        print("[UserProfileContentView] Loading posts for userId: \(user.id) (\(user.name))")
        isLoadingPosts = true

        // Seed posts first — no network needed
        let seedPosts = MockDataProvider.posts(forUser: user.id)
        if !seedPosts.isEmpty {
            print("[UserProfileContentView] Found \(seedPosts.count) seed posts")
            userPosts = seedPosts
            isLoadingPosts = false
            return
        }

        // Supabase fallback
        print("[UserProfileContentView] No seed posts — fetching from Supabase by name: \(user.name)")
        userPosts = (try? await SupabaseService.shared.getPostsByAuthor(authorName: user.name)) ?? []
        print("[UserProfileContentView] Fetched \(userPosts.count) posts from Supabase")
        isLoadingPosts = false
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            // Cover photo / banner
            ZStack(alignment: .bottomTrailing) {
                if let coverUrl = user.coverImageUrl, let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            coverGradient
                        }
                    }
                    .frame(height: 140)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.25)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                } else {
                    coverGradient.frame(height: 140)
                }
            }

            // White card below banner
            VStack(alignment: .leading, spacing: 0) {
                // Avatar row
                HStack(alignment: .bottom) {
                    avatarCircle
                        .offset(y: -42)
                        .padding(.bottom, -42)
                    Spacer()
                    if !isOwnProfile && !appState.isGuest && appState.currentUserId != nil {
                        FollowButton(followingId: user.id.uuidString, followingType: "worshipper")
                            .padding(.top, 10)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                // Name + bio + location / denomination
                VStack(alignment: .leading, spacing: 8) {
                    Text(user.name)
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.lcText)

                    let bio = user.bio ?? ""
                    Text(bio.isEmpty ? "No bio added yet." : bio)
                        .font(bio.isEmpty ? .system(size: 14).italic() : .system(size: 14))
                        .foregroundColor(bio.isEmpty ? .lcText3 : .lcText2)
                        .lineSpacing(3)
                        .lineLimit(3)

                    HStack(spacing: 8) {
                        let city = user.city ?? ""
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                            Text(city.isEmpty ? "—" : city)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.lcText3)

                        let denom = user.denomination ?? ""
                        if !denom.isEmpty {
                            Text(denom)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.lcNavy)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.lcNavy.opacity(0.09))
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(Color.white)
        }
    }

    private var coverGradient: some View {
        LinearGradient(
            colors: [.lcNavy, .lcNavyDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "cross.fill")
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.06))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 20)
        )
    }

    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 88, height: 88)
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
            UserAvatarView(user: user, size: .large)
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 88, height: 88)
        }
    }

    // MARK: - Stats Strip

    private var statsStrip: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                statButton(count: followerEntries.count,  label: "Followers",
                           allowed: canView(user.followersPrivacy)) { showFollowersSheet = true }
                Divider().frame(height: 32)
                statButton(count: followingEntries.count, label: "Following",
                           allowed: canView(user.followingPrivacy)) { showFollowingSheet = true }
                Divider().frame(height: 32)
                statButton(count: profileChurches.count,  label: "Churches",
                           allowed: canView(user.churchesPrivacy)) { showChurchesSheet = true }
            }
            .padding(.vertical, 14)
            .background(Color.white)
            Divider()
        }
    }

    private func statButton(count: Int, label: String, allowed: Bool, action: @escaping () -> Void) -> some View {
        Button {
            if allowed { action() }
        } label: {
            VStack(spacing: 3) {
                if allowed {
                    Text("\(count)")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.lcText)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.lcText3)
                }
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.lcText3)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(UserProfileTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { selectedTab = tab }
                } label: {
                    VStack(spacing: 0) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: selectedTab == tab ? .bold : .regular))
                            .foregroundColor(selectedTab == tab ? .lcNavy : .lcText3)
                            .padding(.vertical, 13)
                        Rectangle()
                            .fill(selectedTab == tab ? Color.lcNavy : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .posts:    postsTab
        case .about:    aboutTab
        case .churches: churchesTab
        case .activity: activityTab
        }
    }

    // MARK: - Posts Tab

    private var postsTab: some View {
        VStack(spacing: 12) {
            if isLoadingPosts {
                ProgressView().tint(.lcNavy).padding(.top, 32)
            } else if userPosts.isEmpty {
                emptyState(
                    icon: "text.bubble",
                    title: "No posts yet",
                    subtitle: isOwnProfile
                        ? "Use the Posts tab to share with the community."
                        : "\(user.name.components(separatedBy: " ").first ?? "This user") hasn't posted yet."
                )
            } else {
                ForEach(userPosts) { post in
                    userPostCard(post)
                }
            }
        }
        .padding(16)
    }

    private func userPostCard(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 14))
                    .foregroundColor(.lcText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let urlStr = post.photoUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(10)
                    }
                }
            }
            HStack {
                Text(postTimeAgo(post.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(.lcText3)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                    Text("\(post.likeCount)")
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private func postTimeAgo(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        switch diff {
        case ..<3600:   return "\(Int(diff / 60))m ago"
        case ..<86400:  return "\(Int(diff / 3600))h ago"
        default:        return "\(Int(diff / 86400))d ago"
        }
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 10) {
            aboutCard(icon: "text.alignleft", title: "Bio") {
                let bio = user.bio ?? ""
                Text(bio.isEmpty ? "No bio added yet." : bio)
                    .font(bio.isEmpty ? .system(size: 14).italic() : .system(size: 14))
                    .foregroundColor(bio.isEmpty ? .lcText3 : .lcText2)
                    .lineSpacing(4)
            }

            aboutCard(icon: "building.columns.fill", title: "Denomination") {
                let denom = user.denomination ?? ""
                Text(denom.isEmpty ? "—" : denom)
                    .font(denom.isEmpty ? .system(size: 14).italic() : .system(size: 14))
                    .foregroundColor(denom.isEmpty ? .lcText3 : .lcText2)
            }

            aboutCard(icon: "mappin.circle.fill", title: "Location") {
                let city = user.city ?? ""
                Text(city.isEmpty ? "—" : city)
                    .font(city.isEmpty ? .system(size: 14).italic() : .system(size: 14))
                    .foregroundColor(city.isEmpty ? .lcText3 : .lcText2)
            }

            aboutCard(icon: "house.fill", title: "Home Church") {
                let name = profileChurches.first?.name ?? ""
                Text(name.isEmpty ? "Not set" : name)
                    .font(name.isEmpty ? .system(size: 14).italic() : .system(size: 14, weight: .medium))
                    .foregroundColor(name.isEmpty ? .lcText3 : .lcText2)
            }

            aboutCard(icon: "calendar", title: "Member Since") {
                Text("—")
                    .font(.system(size: 14).italic())
                    .foregroundColor(.lcText3)
            }
        }
        .padding(16)
    }

    private func aboutCard<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.lcNavy.opacity(0.08))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.lcNavy)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lcText3)
                    .textCase(.uppercase)
                    .tracking(0.4)
                content()
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Churches Tab

    private var churchesTab: some View {
        VStack(spacing: 12) {
            if !canView(user.churchesPrivacy) {
                privacyLockedState(ownerFirstName: user.name.components(separatedBy: " ").first ?? "This user")
            } else if profileChurches.isEmpty {
                emptyState(
                    icon: "building.2",
                    title: "No churches followed yet",
                    subtitle: "This person hasn't followed any churches yet."
                )
            } else {
                ForEach(profileChurches) { church in
                    NavigationLink(destination: ChurchDetailView(church: church)) {
                        churchFollowCard(church)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
    }

    private func churchFollowCard(_ church: Church) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: church.image)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Color.lcNavy.opacity(0.1)
                        .overlay(
                            Image(systemName: "building.2")
                                .font(.system(size: 20))
                                .foregroundColor(.lcText3)
                        )
                }
            }
            .frame(width: 72, height: 72)
            .clipped()
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(church.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.lcText)
                        .lineLimit(1)
                    if church.isLive { LiveBadge() }
                }
                if !church.denomination.isEmpty {
                    Text(church.denomination)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.lcNavy)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.lcNavy.opacity(0.08))
                        .cornerRadius(20)
                }
                if !church.about.isEmpty {
                    Text(church.about)
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.lcText3.opacity(0.5))
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Activity Tab

    private var activityTab: some View {
        VStack(spacing: 0) {
            if !canView(user.activityPrivacy) {
                privacyLockedState(ownerFirstName: user.name.components(separatedBy: " ").first ?? "This user")
            } else if activityItems.isEmpty {
                emptyState(
                    icon: "clock.arrow.circlepath",
                    title: "No activity yet",
                    subtitle: "Activity will appear here as they engage."
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activityItems.enumerated()), id: \.offset) { idx, item in
                        if idx > 0 { Divider().padding(.leading, 56) }
                        activityRow(item)
                    }
                }
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
        }
        .padding(16)
    }

    private func activityRow(_ item: ActivityEntry) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: item.icon)
                    .font(.system(size: 14))
                    .foregroundColor(item.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.lcText)
                if let sub = item.sub, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // MARK: - Helpers

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 38))
                .foregroundColor(.lcText3)
                .padding(.top, 52)
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.lcText)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 40)
    }

    private func privacyLockedState(ownerFirstName: String) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.lcNavy.opacity(0.07))
                    .frame(width: 70, height: 70)
                Image(systemName: "lock.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.lcNavy.opacity(0.4))
            }
            .padding(.top, 52)
            Text("This is private")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.lcText)
            Text("\(ownerFirstName) has set this to private.")
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 40)
    }
}

// MARK: - Activity Entry model (local to this file)

private struct ActivityEntry {
    let icon:  String
    let color: Color
    let text:  String
    let sub:   String?
}

// MARK: - Church List Sheet

struct ChurchListSheet: View {
    @Environment(\.dismiss) private var dismiss
    let churches: [Church]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                if churches.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "building.2")
                            .font(.system(size: 48))
                            .foregroundColor(Color(.tertiaryLabel))
                        Text("No churches followed yet")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(.label))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(churches) { church in
                        NavigationLink(destination: ChurchDetailView(church: church)) {
                            HStack(spacing: 14) {
                                AsyncImage(url: URL(string: church.image)) { phase in
                                    if case .success(let img) = phase {
                                        img.resizable().scaledToFill()
                                    } else {
                                        Color.lcNavy.opacity(0.1)
                                    }
                                }
                                .frame(width: 48, height: 48)
                                .clipped()
                                .cornerRadius(8)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(church.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.lcText)
                                    if !church.denomination.isEmpty {
                                        Text(church.denomination)
                                            .font(.system(size: 12))
                                            .foregroundColor(.lcText3)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Churches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
