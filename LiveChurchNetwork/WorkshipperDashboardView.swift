import SwiftUI
import PhotosUI

// MARK: - Tab enum

private enum UserProfileTab: String, CaseIterable {
    case posts    = "Posts"
    case about    = "About"
    case churches = "Churches"
    case activity = "Activity"
}

// MARK: - Worshipper Dashboard

struct WorkshipperDashboardView: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedTab: UserProfileTab = .about
    @State private var followedChurches: [Church] = []
    @State private var allFollows: [Follow] = []
    @State private var followerCount = 0
    @State private var isLoading = true
    @State private var showSignOutAlert = false
    @State private var showEditProfile = false

    @State private var showPrivacySettings = false
    @State private var showFollowersSheet = false
    @State private var showFollowingSheet = false
    @State private var followerEntries: [FollowEntry] = []
    @State private var followingEntries: [FollowEntry] = []

    // Photo / cover upload
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedCoverItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var isUploadingCover = false
    @State private var uploadError: String?

    // Posts
    @State private var userPosts: [Post] = []
    @State private var isLoadingPosts = false
    @State private var showCreatePost = false

    private var profile: Profile? { self.appState.profile }

    private var initials: String {
        let name = profile?.fullName ?? ""
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
        return "U"
    }

    var body: some View {
        NavigationStack {
            Group {
                if self.appState.isGuest {
                    guestPrompt
                } else {
                    profileContent
                }
            }
            .background(Color.lcCream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showEditProfile = true } label: {
                            Label("Edit Profile", systemImage: "pencil")
                        }
                        Button { showPrivacySettings = true } label: {
                            Label("Privacy Settings", systemImage: "lock.shield")
                        }
                        Divider()
                        Button(role: .destructive) { showSignOutAlert = true } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        avatarNavButton
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                if let p = profile, let userId = self.appState.currentUserId {
                    EditWorshipperProfileView(profile: p, userId: userId) {
                        Task { await self.appState.loadProfile() }
                    }
                }
            }
            .sheet(isPresented: $showPrivacySettings) {
                if let p = profile, let userId = self.appState.currentUserId {
                    PrivacySettingsView(profile: p, userId: userId) {
                        Task { await self.appState.loadProfile() }
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { await self.appState.signOut() }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Upload Failed", isPresented: Binding(
                get: { uploadError != nil },
                set: { if !$0 { uploadError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(uploadError ?? "")
            }
        }
        .task { await loadAll() }
    }

    // MARK: - Main content

    private var profileContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                statsStrip
                tabBar
                    .background(Color.white)
                Rectangle()
                    .fill(Color.lcBorder)
                    .frame(height: 1)
                tabContent
                    .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            // Cover photo / banner
            ZStack(alignment: .bottomTrailing) {
                if let coverStr = self.appState.profile?.coverUrl, let url = URL(string: coverStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            coverGradient
                        }
                    }
                    .frame(height: 130)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.22)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                } else {
                    coverGradient.frame(height: 130)
                }

                // Cover upload button
                if isUploadingCover {
                    ProgressView().tint(.white)
                        .padding(.horizontal, 14).padding(.bottom, 12)
                } else {
                    PhotosPicker(selection: $selectedCoverItem, matching: .images) {
                        HStack(spacing: 5) {
                            Image(systemName: "camera.fill").font(.system(size: 11))
                            Text("Change Cover").font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Color.black.opacity(0.35))
                        .cornerRadius(20)
                    }
                    .onChange(of: selectedCoverItem) { item in
                        Task { await handleCoverSelection(item) }
                    }
                    .padding(.horizontal, 12).padding(.bottom, 12)
                }
            }

            // White card below banner
            VStack(alignment: .leading, spacing: 0) {
                // Avatar row
                HStack(alignment: .bottom) {
                    avatarCircle
                        .offset(y: -38)
                        .padding(.bottom, -38)
                    Spacer()
                    Button {
                        showEditProfile = true
                    } label: {
                        Text("Edit Profile")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcNavy)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.lcNavy, lineWidth: 1.5)
                            )
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                // Name + bio + location/denomination
                VStack(alignment: .leading, spacing: 8) {
                    Text(profile?.fullName ?? "User Name")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.lcText)

                    let bio = profile?.bio ?? ""
                    Text(bio.isEmpty ? "No bio added yet." : bio)
                        .font(bio.isEmpty ? .system(size: 14).italic() : .system(size: 14))
                        .foregroundColor(bio.isEmpty ? .lcText3 : .lcText2)
                        .lineSpacing(3)
                        .lineLimit(3)

                    HStack(spacing: 8) {
                        let city = profile?.city ?? ""
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                            Text(city.isEmpty ? "—" : city)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.lcText3)

                        let denom = profile?.denomination ?? ""
                        Text(denom.isEmpty ? "—" : denom)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(denom.isEmpty ? .lcText3 : .lcNavy)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.lcNavy.opacity(denom.isEmpty ? 0.04 : 0.09))
                            .cornerRadius(20)
                    }

                    // Home church row — directory churches link to ChurchDetailView,
                    // custom-name churches show as plain text (no detail view exists).
                    if let slug = profile?.homeChurchSlug,
                       let submission = self.appState.church(bySlug: slug) {
                        let church = self.appState.toChurch(submission)
                        NavigationLink {
                            ChurchDetailView(church: church)
                        } label: {
                            homeChurchLabel(church.name)
                        }
                        .buttonStyle(.plain)
                    } else if let customName = profile?.homeChurchName,
                              !customName.isEmpty {
                        homeChurchLabel(customName)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(Color.white)
        }
    }

    private func homeChurchLabel(_ name: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "house.fill")
                .font(.system(size: 11))
                .foregroundColor(.lcGold)
            Text("Member at ")
                .font(.system(size: 12))
                .foregroundColor(.lcText3)
            + Text(name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.lcNavy)
        }
    }

    private var coverGradient: some View {
        LinearGradient(colors: [.lcNavy, .lcNavyDark], startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(
                Image(systemName: "cross.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.06))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 20)
            )
    }

    private var avatarCircle: some View {
        ZStack(alignment: .bottomTrailing) {
            // White ring + photo
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 84, height: 84)
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)

                if let urlStr = self.appState.profile?.photoUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            initialsCircle
                        }
                    }
                    .frame(width: 78, height: 78)
                    .clipShape(Circle())
                } else {
                    initialsCircle
                        .frame(width: 78, height: 78)
                }

                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 84, height: 84)

                if isUploadingPhoto {
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 78, height: 78)
                    ProgressView().tint(.white)
                }
            }

            // Camera badge
            if !isUploadingPhoto {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack {
                        Circle().fill(Color.white).frame(width: 28, height: 28)
                        Circle().fill(Color.lcNavy).frame(width: 24, height: 24)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    }
                }
                .onChange(of: selectedPhotoItem) { item in
                    Task { await handlePhotoSelection(item) }
                }
                .offset(x: 2, y: 2)
            }
        }
    }

    private var initialsCircle: some View {
        ZStack {
            Circle().fill(Color.lcNavy)
            Text(initials)
                .font(.system(size: 26, weight: .black))
                .foregroundColor(.lcGold)
        }
    }

    // MARK: - Stats Strip

    private var statsStrip: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                statButton(value: followerCount, label: "Followers") {
                    showFollowersSheet = true
                }
                Divider().frame(height: 32)
                statButton(value: allFollows.filter { $0.followingType == "worshipper" }.count, label: "Following") {
                    showFollowingSheet = true
                }
                Divider().frame(height: 32)
                statButton(value: followedChurches.count, label: "Churches") {
                    withAnimation(.easeInOut(duration: 0.16)) { selectedTab = .churches }
                }
            }
            .padding(.vertical, 14)
            .background(Color.white)
            Divider()
        }
        .sheet(isPresented: $showFollowersSheet) {
            FollowListSheet(title: "Followers", entries: followerEntries)
        }
        .sheet(isPresented: $showFollowingSheet) {
            FollowListSheet(title: "Following", entries: followingEntries)
        }
    }

    private func statButton(value: Int, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text("\(value)")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.lcText)
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

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 10) {
            aboutCard(icon: "text.alignleft", title: "Bio") {
                let bio = profile?.bio ?? ""
                Text(bio.isEmpty ? "No bio added yet." : bio)
                    .font(bio.isEmpty ? .system(size: 14).italic() : .system(size: 14))
                    .foregroundColor(bio.isEmpty ? .lcText3 : .lcText2)
                    .lineSpacing(4)
            }

            aboutCard(icon: "building.columns.fill", title: "Denomination") {
                let denom = profile?.denomination ?? ""
                Text(denom.isEmpty ? "—" : denom)
                    .font(denom.isEmpty ? .system(size: 14).italic() : .system(size: 14))
                    .foregroundColor(denom.isEmpty ? .lcText3 : .lcText2)
            }

            aboutCard(icon: "mappin.circle.fill", title: "Location") {
                let city = profile?.city ?? ""
                Text(city.isEmpty ? "—" : city)
                    .font(city.isEmpty ? .system(size: 14).italic() : .system(size: 14))
                    .foregroundColor(city.isEmpty ? .lcText3 : .lcText2)
            }

            aboutCard(icon: "house.fill", title: "Home Church") {
                let name = followedChurches.first?.name ?? ""
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

    private func aboutCard<Content: View>(icon: String, title: String,
                                          @ViewBuilder content: () -> Content) -> some View {
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
            if followedChurches.isEmpty {
                emptyState(icon: "building.2",
                           title: "No churches followed yet",
                           subtitle: "Explore the Discover tab to find churches near you.")
            } else {
                ForEach(followedChurches) { church in
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
            // Thumbnail
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
            if followedChurches.isEmpty && allFollows.isEmpty {
                emptyState(icon: "clock.arrow.circlepath",
                           title: "No activity yet",
                           subtitle: "Activity will appear here as you engage.")
            } else {
                VStack(spacing: 0) {
                    activityRow(icon: "person.badge.plus",
                                color: .lcNavy,
                                text: "Joined Live Church Network",
                                sub: nil)

                    ForEach(Array(followedChurches.prefix(10)), id: \.id) { church in
                        Divider().padding(.leading, 56)
                        activityRow(icon: "building.2.fill",
                                    color: .lcGold,
                                    text: "Followed \(church.name)",
                                    sub: church.denomination.isEmpty ? nil : church.denomination)
                    }

                    ForEach(Array(allFollows.filter { $0.followingType == "worshipper" }.prefix(5))) { _ in
                        Divider().padding(.leading, 56)
                        activityRow(icon: "person.fill.badge.plus",
                                    color: .lcTeal,
                                    text: "Followed a worshipper",
                                    sub: nil)
                    }
                }
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                .padding(16)
            }
        }
    }

    private func activityRow(icon: String, color: Color, text: String, sub: String?) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.lcText)
                if let sub, !sub.isEmpty {
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

    // MARK: - Shared helpers

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

    private var avatarNavButton: some View {
        ZStack {
            Circle().fill(Color.lcNavy).frame(width: 32, height: 32)
            if let urlStr = self.appState.profile?.photoUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                    } else {
                        Text(initials)
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.lcGold)
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Text(initials)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.lcGold)
            }
        }
    }

    // MARK: - Posts Tab

    private var postsTab: some View {
        VStack(spacing: 12) {
            // Compose prompt
            Button { showCreatePost = true } label: {
                HStack(spacing: 12) {
                    initialsCircle
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                    Text("Share something with the community…")
                        .font(.system(size: 14))
                        .foregroundColor(.lcText3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18))
                        .foregroundColor(.lcNavy)
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showCreatePost) {
                CreatePostView { Task { await loadPosts() } }
            }

            if isLoadingPosts {
                ProgressView().tint(.lcNavy).padding(.top, 24)
            } else if userPosts.isEmpty {
                emptyState(
                    icon: "text.bubble",
                    title: "No posts yet",
                    subtitle: "Share your faith journey, thoughts, or prayer requests with the community."
                )
            } else {
                ForEach(userPosts) { post in
                    profilePostCard(post)
                }
            }
        }
        .padding(16)
    }

    private func profilePostCard(_ post: Post) -> some View {
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
                Text(timeAgo(post.createdAt))
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

    private func timeAgo(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        switch diff {
        case ..<3600:   return "\(Int(diff / 60))m ago"
        case ..<86400:  return "\(Int(diff / 3600))h ago"
        default:        return "\(Int(diff / 86400))d ago"
        }
    }

    // MARK: - Guest prompt

    private var guestPrompt: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 52))
                .foregroundColor(.lcNavy.opacity(0.35))
            Text("Create a free account")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.lcText)
            Text("Sign up to save churches, get personalized recommendations, and more.")
                .font(.system(size: 14))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                self.appState.isGuest = false
            } label: {
                Text("Sign Up / Sign In")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.lcNavy)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
        .background(Color.lcCream)
    }

    // MARK: - Load

    private func loadAll() async {
        // Capture appState for use in async context
        let state = self.appState
        guard let userId = state.currentUserId else { isLoading = false; return }

        // 1. Fetch all follow data concurrently
        async let followsTask   = SupabaseService.shared.getFollowing(followerId: userId)
        async let followersTask = SupabaseService.shared.getFollowers(userId: userId)
        async let countTask     = SupabaseService.shared.getFollowerCount(followingId: userId.uuidString)

        let follows   = (try? await followsTask)   ?? []
        let followers = (try? await followersTask) ?? []
        let realCount = (try? await countTask)     ?? 0

        print("[loadAll] follows: \(follows.count), followers: \(followers.count), followerCount: \(realCount)")

        // 2. Resolve IDs — do this before any profile fetches
        let churchSlugs   = Set(follows.filter { $0.followingType == "church" }.map { $0.followingId })
        let computedChurches = state.churches(bySlugs: churchSlugs)

        let followerIds   = followers.map { $0.followerId }
        let followingIds  = follows
            .filter { $0.followingType == "worshipper" }
            .compactMap { UUID(uuidString: $0.followingId) }

        print("[loadAll] followerIds: \(followerIds.count), followingIds: \(followingIds.count)")

        // 3. Fetch profiles for both lists concurrently
        async let followerProfilesTask  = SupabaseService.shared.getProfiles(ids: followerIds)
        async let followingProfilesTask = SupabaseService.shared.getProfiles(ids: followingIds)

        let followerProfiles  = (try? await followerProfilesTask)  ?? []
        let followingProfiles = (try? await followingProfilesTask) ?? []

        print("[loadAll] resolved follower profiles: \(followerProfiles.count), following profiles: \(followingProfiles.count)")

        // 4. Build entries — Supabase profile first, then seed data fallback
        let followerProfileMap  = Dictionary(uniqueKeysWithValues: followerProfiles.map  { ($0.id, $0) })
        let followingProfileMap = Dictionary(uniqueKeysWithValues: followingProfiles.map { ($0.id, $0) })

        func makeEntry(id: UUID, profileMap: [UUID: Profile]) -> FollowEntry {
            if let p = profileMap[id] {
                return FollowEntry(
                    id: id,
                    displayName: p.fullName ?? "LCN Member",
                    photoUrl: p.photoUrl,
                    subtitle: p.denomination ?? p.city
                )
            }
            if let seed = MockDataProvider.allSeedUsers.first(where: { $0.id == id }) {
                return FollowEntry(
                    id: id,
                    displayName: seed.name,
                    photoUrl: seed.photoUrl,
                    subtitle: seed.denomination ?? seed.city
                )
            }
            return FollowEntry(id: id, displayName: "LCN Member", photoUrl: nil, subtitle: nil)
        }

        let computedFollowerEntries  = followerIds.map  { makeEntry(id: $0, profileMap: followerProfileMap) }
        let computedFollowingEntries = followingIds.map { makeEntry(id: $0, profileMap: followingProfileMap) }

        // 5. Apply ALL state at once so counts and lists are always in sync
        allFollows       = follows
        followerCount    = realCount
        followedChurches = computedChurches
        followerEntries  = computedFollowerEntries
        followingEntries = computedFollowingEntries

        isLoading = false

        await loadPosts()
    }

    private func loadPosts() async {
        let state = self.appState
        guard let name = state.profile?.fullName, !name.isEmpty else { return }
        isLoadingPosts = true
        userPosts = (try? await SupabaseService.shared.getPostsByAuthor(authorName: name)) ?? []
        isLoadingPosts = false
    }

    // MARK: - Photo upload handlers

    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let compressed = compressImage(data),
              let userId = self.appState.currentUserId else { return }
        isUploadingPhoto = true
        do {
            let url = try await SupabaseService.shared.uploadProfileImage(
                userId: userId, data: compressed, bucket: "avatars")
            try await SupabaseService.shared.updateProfilePhotoUrl(userId: userId, photoUrl: url)
            await self.appState.loadProfile()
        } catch {
            uploadError = "Photo upload failed: \(error.localizedDescription)"
        }
        isUploadingPhoto = false
    }

    private func handleCoverSelection(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let compressed = compressImage(data),
              let userId = self.appState.currentUserId else { return }
        isUploadingCover = true
        do {
            let url = try await SupabaseService.shared.uploadProfileImage(
                userId: userId, data: compressed, bucket: "covers")
            try await SupabaseService.shared.updateProfileCoverUrl(userId: userId, coverUrl: url)
            await self.appState.loadProfile()
        } catch {
            uploadError = "Cover upload failed: \(error.localizedDescription)"
        }
        isUploadingCover = false
    }

    private func compressImage(_ data: Data) -> Data? {
        guard let uiImage = UIImage(data: data) else { return nil }
        return uiImage.jpegData(compressionQuality: 0.72)
    }
}

// MARK: - Follow List Sheet

struct FollowEntry: Identifiable {
    let id: UUID
    let displayName: String
    let photoUrl: String?
    let subtitle: String?   // denomination or city
}

struct FollowListSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let entries: [FollowEntry]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                if entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 48))
                            .foregroundColor(Color(.tertiaryLabel))
                        Text("No \(title.lowercased()) yet")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(.label))
                        Text(title == "Followers"
                             ? "People who follow you will appear here."
                             : "People you follow will appear here.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.secondaryLabel))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(entries) { entry in
                        NavigationLink(destination: UserProfileView(userId: entry.id)) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(Color.lcNavy)
                                        .frame(width: 44, height: 44)
                                    if let urlStr = entry.photoUrl, let url = URL(string: urlStr) {
                                        AsyncImage(url: url) { phase in
                                            if case .success(let img) = phase {
                                                img.resizable().scaledToFill()
                                                    .frame(width: 44, height: 44)
                                                    .clipShape(Circle())
                                            } else {
                                                initialsText(entry.displayName)
                                            }
                                        }
                                    } else {
                                        initialsText(entry.displayName)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(entry.displayName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.lcText)
                                    if let sub = entry.subtitle, !sub.isEmpty {
                                        Text(sub)
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func initialsText(_ name: String) -> some View {
        let parts = name.split(separator: " ")
        let initials: String
        if parts.count >= 2 {
            initials = "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        } else if !name.isEmpty {
            initials = String(name.prefix(2)).uppercased()
        } else {
            initials = "?"
        }
        return Text(initials)
            .font(.system(size: 15, weight: .black))
            .foregroundColor(.lcGold)
    }
}

// MARK: - Edit Worshipper Profile

struct EditWorshipperProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    let profile: Profile
    let userId: UUID
    let onSave: () -> Void

    @State private var fullName: String
    @State private var city: String
    @State private var denomination: String
    @State private var bio: String
    @State private var homeChurchSlug: String?
    @State private var homeChurchName: String?
    @State private var showHomeChurchPicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let originalHomeChurchSlug: String?

    init(profile: Profile, userId: UUID, onSave: @escaping () -> Void) {
        self.profile  = profile
        self.userId   = userId
        self.onSave   = onSave
        _fullName       = State(initialValue: profile.fullName ?? "")
        _city           = State(initialValue: profile.city ?? "")
        _denomination   = State(initialValue: profile.denomination ?? "")
        _bio            = State(initialValue: profile.bio ?? "")
        _homeChurchSlug = State(initialValue: profile.homeChurchSlug)
        _homeChurchName = State(initialValue: profile.homeChurchName)
        self.originalHomeChurchSlug = profile.homeChurchSlug
    }

    private var homeChurchDisplayName: String? {
        if let slug = homeChurchSlug,
           let submission = self.appState.church(bySlug: slug) {
            return submission.churchName
        }
        if let name = homeChurchName, !name.isEmpty {
            return name
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Info") {
                    LabeledContent("Name") {
                        TextField("Your name", text: $fullName)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("City") {
                        TextField("City, State", text: $city)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Denomination") {
                        TextField("e.g. Baptist", text: $denomination)
                            .multilineTextAlignment(.trailing)
                    }
                    Button {
                        showHomeChurchPicker = true
                    } label: {
                        HStack {
                            Text("Home Church")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(homeChurchDisplayName ?? "None")
                                .foregroundColor(homeChurchDisplayName == nil ? .secondary : .lcNavy)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section("Bio") {
                    TextEditor(text: $bio)
                        .frame(minHeight: 80)
                        .font(.system(size: 14))
                }
                if let error = errorMessage {
                    Section {
                        Text(error).foregroundColor(.red).font(.system(size: 13))
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showHomeChurchPicker) {
                HomeChurchPickerSheet(
                    selectedSlug: $homeChurchSlug,
                    customName:   $homeChurchName
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .bold()
                        .disabled(isSaving || fullName.isEmpty)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await SupabaseService.shared.updateProfile(
                userId:         userId,
                fullName:       fullName,
                city:           city,
                denomination:   denomination,
                bio:            bio,
                homeChurchSlug: homeChurchSlug,
                homeChurchName: homeChurchName
            )
            // If the home church changed to a new directory slug, follow it so
            // its posts appear in the user's feed. Custom-name churches don't
            // have a slug to follow. We deliberately do NOT auto-unfollow the
            // previous home church — the user may still want updates.
            if let newSlug = homeChurchSlug, newSlug != originalHomeChurchSlug {
                try? await SupabaseService.shared.follow(
                    followerId: userId, followingId: newSlug, followingType: "church")
            }
            onSave()
            dismiss()
        } catch {
            errorMessage = "Could not save changes. Please try again."
        }
        isSaving = false
    }
}
