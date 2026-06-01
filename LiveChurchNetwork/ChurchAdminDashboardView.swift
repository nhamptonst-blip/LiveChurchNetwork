import SwiftUI
import PhotosUI

struct ChurchAdminDashboardView: View {
    @EnvironmentObject var appState: AppState

    @State private var submission: ChurchSubmission?
    @State private var isLoading = true

    @State private var posts: [Post] = []
    @State private var events: [Event] = []

    // Derived counts powering the visibility score's "recent posts" and
    // "upcoming events" weighted factors. Recompute on every render so they
    // stay in sync with the @State arrays without manual invalidation.
    private var recentPostCountThisWeek: Int {
        let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return posts.filter { $0.createdAt >= cutoff }.count
    }
    private var upcomingEventCount: Int {
        let now = Date()
        return events.filter { $0.eventDate > now }.count
    }

    /// Compute the visibility score and return it only when there's still
    /// something to recommend. Returns nil at score 100 so the parent view
    /// can hide the Smart Recommendations card entirely.
    private func visibilityIfIncomplete(_ sub: ChurchSubmission) -> VisibilityResult? {
        let result = VisibilityScoreEngine.compute(
            sub,
            signals: VisibilityScoreEngine.Signals(
                recentPostCount: recentPostCountThisWeek,
                upcomingEventCount: upcomingEventCount
            )
        )
        return result.score >= 100 ? nil : result
    }
    @State private var inquiries: [ChurchInquiry] = []
    @State private var followerEntries: [FollowEntry] = []

    @State private var selectedTab: DashboardTab = .overview
    @State private var contentSubTab: ContentSubTab = .posts
    @State private var pinnedPostIds: Set<UUID> = []

    @State private var showEditSheet = false
    @State private var showPostSheet = false
    @State private var showEventSheet = false
    @State private var showSignOutAlert = false
    @State private var showBlockedAccounts = false
    @State private var showDeleteAccount = false
    @State private var showNotificationPrefs = false
    /// Carries the post-type chosen from QuickComposer's tile grid into the
    /// CreatePostView sheet so the right composer mode is pre-selected.
    @State private var pendingPostType: String?

    @State private var postToDelete: Post?
    @State private var eventToDelete: Event?

    @State private var coverPickerItem: PhotosPickerItem?
    @State private var logoPickerItem: PhotosPickerItem?
    @State private var isUploadingCover = false
    @State private var isUploadingLogo = false
    @State private var uploadError: String?

    @State private var isTogglingLive = false

    enum DashboardTab: String, CaseIterable, Identifiable {
        case overview, content, audience, inbox, live, settings
        var id: String { rawValue }
        var label: String {
            switch self {
            case .overview:  return "Overview"
            case .content:   return "Content"
            case .audience:  return "Audience"
            case .inbox:     return "Inbox"
            case .live:      return "Live"
            case .settings:  return "Settings"
            }
        }
        var icon: String {
            switch self {
            case .overview:  return "house.fill"
            case .content:   return "square.stack.fill"
            case .audience:  return "person.2.fill"
            case .inbox:     return "envelope.fill"
            case .live:      return "dot.radiowaves.left.and.right"
            case .settings:  return "gearshape.fill"
            }
        }
    }

    enum ContentSubTab: String, CaseIterable {
        case posts, events
    }

    private var newInquiryCount: Int {
        inquiries.lazy.filter { $0.status == "new" }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading your church...").tint(.lcNavy)
                } else if let sub = submission {
                    loadedContent(sub)
                } else {
                    noSubmissionState
                }
            }
            .background(Color.lcCream)
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditSheet) {
                if let sub = submission {
                    EditChurchProfileView(submission: sub) { updated in
                        submission = updated
                    }
                }
            }
            .sheet(isPresented: $showPostSheet, onDismiss: { pendingPostType = nil }) {
                CreatePostView(initialPostType: pendingPostType, onPosted: { await reload() })
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showEventSheet) {
                CreateEventView(onCreated: { await reload() })
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showBlockedAccounts) {
                NavigationStack {
                    BlockedAccountsView()
                        .environmentObject(appState)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { showBlockedAccounts = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showDeleteAccount) {
                NavigationStack {
                    DeleteAccountView().environmentObject(appState)
                }
            }
            .sheet(isPresented: $showNotificationPrefs) {
                NavigationStack {
                    NotificationPreferencesView()
                        .environmentObject(appState)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { showNotificationPrefs = false }
                            }
                        }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { await appState.signOut() }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Post", isPresented: Binding(
                get: { postToDelete != nil },
                set: { if !$0 { postToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { postToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let post = postToDelete {
                        Task { await deletePost(post) }
                    }
                }
            } message: {
                Text("This can't be undone.")
            }
            .alert("Delete Event", isPresented: Binding(
                get: { eventToDelete != nil },
                set: { if !$0 { eventToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { eventToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let event = eventToDelete {
                        Task { await deleteEvent(event) }
                    }
                }
            } message: {
                Text("This can't be undone.")
            }
        }
        .task { await loadAll() }
    }

    // MARK: - Shell

    @ViewBuilder
    private func loadedContent(_ sub: ChurchSubmission) -> some View {
        VStack(spacing: 0) {
            brandedHeader(sub)
            tabBar
            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .overview:  overviewTab(sub)
                    case .content:   contentTab
                    case .audience:  audienceTab
                    case .inbox:     inboxTab(sub)
                    case .live:      liveTab(sub)
                    case .settings:  settingsTab
                    }
                }
                .padding(16)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Branded Header

    private func brandedHeader(_ sub: ChurchSubmission) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let coverUrl = appState.profile?.coverUrl,
                   let url = URL(string: coverUrl), !coverUrl.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            defaultCoverGradient
                        }
                    }
                } else {
                    defaultCoverGradient
                }
            }
            .frame(height: 140)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.55)],
                    startPoint: .top, endPoint: .bottom
                )
            )

            VStack {
                HStack {
                    Spacer()
                    NavigationLink(destination: ChurchDetailView(church: makePreviewChurch(from: sub))) {
                        HStack(spacing: 5) {
                            Image(systemName: "eye.fill").font(.system(size: 11))
                            Text("Preview").font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    }
                    Menu {
                        Button { selectedTab = .settings } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                        Button { showEditSheet = true } label: {
                            Label("Edit Profile", systemImage: "pencil")
                        }
                        Button { showNotificationPrefs = true } label: {
                            Label("Notifications", systemImage: "bell.badge")
                        }
                        Button { showBlockedAccounts = true } label: {
                            Label("Blocked Accounts", systemImage: "hand.raised")
                        }
                        Button(role: .destructive) { showDeleteAccount = true } label: {
                            Label("Delete Account", systemImage: "trash")
                        }
                        Button(role: .destructive) { showSignOutAlert = true } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 54)
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 12) {
                logoView(sub)
                    .frame(width: 56, height: 56)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .shadow(color: Color.black.opacity(0.25), radius: 4, y: 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text(sub.churchName ?? appState.profile?.fullName ?? "Your Church")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.4), radius: 2)

                    HStack(spacing: 6) {
                        statusPill(sub.status)
                        Text("·").foregroundColor(.white.opacity(0.8))
                        Text("\(followerEntries.count) \(followerEntries.count == 1 ? "follower" : "followers")")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                Spacer()

                if sub.isLive {
                    HStack(spacing: 4) {
                        Circle().fill(Color.red).frame(width: 6, height: 6)
                        Text("LIVE").font(.system(size: 10, weight: .black)).foregroundColor(.white)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(height: 140)
    }

    private var defaultCoverGradient: some View {
        LinearGradient(
            colors: [Color.lcNavy, Color(red: 42/255, green: 79/255, blue: 168/255)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private func logoView(_ sub: ChurchSubmission) -> some View {
        if let photoUrl = appState.profile?.photoUrl,
           let url = URL(string: photoUrl), !photoUrl.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: logoInitials(sub)
                }
            }
            .clipShape(Circle())
        } else {
            logoInitials(sub)
        }
    }

    private func logoInitials(_ sub: ChurchSubmission) -> some View {
        ZStack {
            Circle().fill(Color.lcNavy)
            Text(String((sub.churchName ?? "C").prefix(2)).uppercased())
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.lcGold)
        }
    }

    private func statusPill(_ status: String?) -> some View {
        let (label, color) = statusInfo(status)
        return Text(label)
            .font(.system(size: 9, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(color)
            .cornerRadius(8)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DashboardTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { selectedTab = tab }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon).font(.system(size: 11))
                            Text(tab.label).font(.system(size: 13, weight: .bold))
                            if tab == .inbox && newInquiryCount > 0 {
                                Text("\(newInquiryCount)")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5).padding(.vertical, 1)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundColor(selectedTab == tab ? .white : .lcNavy)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selectedTab == tab ? Color.lcNavy : Color.lcNavy.opacity(0.08))
                        .cornerRadius(22)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }

    // MARK: - Overview Tab

    @ViewBuilder
    private func overviewTab(_ sub: ChurchSubmission) -> some View {
        QuickComposer(
            churchAvatarUrl: sub.avatarUrl,
            churchName: sub.churchName ?? "your church",
            onSelectPostType: { type in
                pendingPostType = type
                showPostSheet = true
            },
            onSelectEvent: { showEventSheet = true }
        )
        quickActionsRow(sub)
        statsCard
        engagementCard

        // Smart Recommendations — only renders while there's something to
        // recommend. Once the church hits 100 the card disappears entirely
        // so the dashboard doesn't keep nagging finished users.
        if let visibility = visibilityIfIncomplete(sub) {
            VisibilityScoreCard(
                result: visibility,
                onTapFactor: { factor in
                    switch factor.key {
                    case "posts":  pendingPostType = "update"; showPostSheet = true
                    case "events": showEventSheet = true
                    default:       showEditSheet = true
                    }
                }
            )
        }

        // Live engagement stream (follows, likes, prayers, comments, inquiries)
        ChurchActivityFeed(
            churchId: sub.id.uuidString,
            churchName: sub.churchName ?? "",
            ownPostIds: posts.map { $0.id.uuidString }
        )

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("RECENT POSTS")
                Spacer()
                if !posts.isEmpty {
                    Button { selectedTab = .content; contentSubTab = .posts } label: {
                        Text("See All →")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.lcNavy)
                    }
                }
            }
            if posts.isEmpty {
                emptyCard(icon: "megaphone.fill",
                          title: "No posts yet",
                          subtitle: "Share your first update with your community.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(posts.prefix(3).enumerated()), id: \.element.id) { idx, post in
                        if idx > 0 { Divider().padding(.leading, 16) }
                        compactPostRow(post)
                    }
                }
                .background(Color.white)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("UPCOMING EVENTS")
                Spacer()
                if !events.isEmpty {
                    Button { selectedTab = .content; contentSubTab = .events } label: {
                        Text("See All →")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.lcNavy)
                    }
                }
            }
            if events.isEmpty {
                emptyCard(icon: "calendar",
                          title: "No upcoming events",
                          subtitle: "Create an event to let people know what's happening.")
            } else {
                VStack(spacing: 10) {
                    ForEach(events.prefix(2)) { event in
                        ChurchEventCard(event: event)
                    }
                }
            }
        }
    }

    private func quickActionsRow(_ sub: ChurchSubmission) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button { Task { await toggleLive(!sub.isLive) } } label: {
                    actionButton(
                        icon: sub.isLive ? "stop.circle.fill" : "play.circle.fill",
                        label: sub.isLive ? "Stop Live" : "Go Live",
                        fg: .white,
                        bg: sub.isLive ? Color.red.opacity(0.8) : Color.red,
                        loading: isTogglingLive
                    )
                }
                .disabled(sub.status != "approved" || isTogglingLive)

                Button { showPostSheet = true } label: {
                    actionButton(icon: "square.and.pencil", label: "New Post",
                                 fg: .lcNavy, bg: Color.lcNavy.opacity(0.08))
                }

                Button { showEventSheet = true } label: {
                    actionButton(icon: "calendar.badge.plus", label: "New Event",
                                 fg: .lcNavy, bg: Color.lcNavy.opacity(0.08))
                }

                Button { selectedTab = .inbox } label: {
                    actionButton(
                        icon: newInquiryCount > 0 ? "envelope.badge.fill" : "envelope.fill",
                        label: newInquiryCount > 0 ? "Inbox (\(newInquiryCount))" : "Inbox",
                        fg: .lcNavy,
                        bg: Color.lcNavy.opacity(0.08)
                    )
                }
            }
        }
    }

    private func actionButton(icon: String, label: String, fg: Color, bg: Color, loading: Bool = false) -> some View {
        HStack(spacing: 6) {
            if loading {
                ProgressView().tint(fg).frame(width: 14, height: 14)
            } else {
                Image(systemName: icon).font(.system(size: 13))
            }
            Text(label).font(.system(size: 13, weight: .bold))
        }
        .foregroundColor(fg)
        .padding(.horizontal, 16).padding(.vertical, 11)
        .background(bg)
        .cornerRadius(22)
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            statItem(value: "\(followerEntries.count)", label: "Followers", icon: "person.2.fill") {
                selectedTab = .audience
            }
            statDivider
            statItem(value: "\(posts.count)", label: "Posts", icon: "square.stack.fill") {
                selectedTab = .content
                contentSubTab = .posts
            }
            statDivider
            statItem(value: "\(events.count)", label: "Events", icon: "calendar") {
                selectedTab = .content
                contentSubTab = .events
            }
            statDivider
            statItem(value: "\(newInquiryCount)", label: "Messages", icon: "envelope.fill") {
                selectedTab = .inbox
            }
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))
    }

    private var engagementCard: some View {
        let totalLikes = posts.reduce(0) { $0 + $1.likeCount }
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.lcGold.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.lcGold)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(totalLikes) total likes")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.lcText)
                Text("across all your posts")
                    .font(.system(size: 12))
                    .foregroundColor(.lcText3)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))
    }

    private func statItem(
        value: String,
        label: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticEngine.impact(.light)
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13)).foregroundColor(.lcNavy.opacity(0.5))
                Text(value).font(.system(size: 20, weight: .black)).foregroundColor(.lcText)
                Text(label).font(.system(size: 10, weight: .semibold)).foregroundColor(.lcText3)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var statDivider: some View {
        Rectangle().fill(Color.lcBorder).frame(width: 1, height: 44)
    }

    // MARK: - Content Tab

    @ViewBuilder
    private var contentTab: some View {
        HStack(spacing: 8) {
            contentSubTabButton(.posts, label: "Posts", count: posts.count)
            contentSubTabButton(.events, label: "Events", count: events.count)
        }

        if contentSubTab == .posts {
            contentPostsList
        } else {
            contentEventsList
        }
    }

    private func contentSubTabButton(_ tab: ContentSubTab, label: String, count: Int) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.15)) { contentSubTab = tab } } label: {
            HStack(spacing: 6) {
                Text(label).font(.system(size: 13, weight: .bold))
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(contentSubTab == tab ? .white.opacity(0.8) : .lcText3)
            }
            .foregroundColor(contentSubTab == tab ? .white : .lcText2)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(contentSubTab == tab ? Color.lcNavy : Color.white)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.lcBorder, lineWidth: contentSubTab == tab ? 0 : 1))
        }
    }

    @ViewBuilder
    private var contentPostsList: some View {
        if posts.isEmpty {
            emptyCard(icon: "megaphone.fill",
                      title: "No posts yet",
                      subtitle: "Tap New Post to share with your community.")
            Button { showPostSheet = true } label: {
                Label("New Post", systemImage: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.lcNavy)
                    .cornerRadius(14)
            }
        } else {
            VStack(spacing: 10) {
                ForEach(sortedPosts) { post in
                    adminPostRow(post)
                }
            }
        }
    }

    @ViewBuilder
    private var contentEventsList: some View {
        if events.isEmpty {
            emptyCard(icon: "calendar",
                      title: "No events yet",
                      subtitle: "Tap New Event to schedule one.")
            Button { showEventSheet = true } label: {
                Label("New Event", systemImage: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.lcNavy)
                    .cornerRadius(14)
            }
        } else {
            VStack(spacing: 10) {
                ForEach(events) { event in
                    adminEventRow(event)
                }
            }
        }
    }

    private var sortedPosts: [Post] {
        posts.sorted { a, b in
            let aPinned = pinnedPostIds.contains(a.id)
            let bPinned = pinnedPostIds.contains(b.id)
            if aPinned != bPinned { return aPinned }
            return a.createdAt > b.createdAt
        }
    }

    private func adminPostRow(_ post: Post) -> some View {
        let isPinned = pinnedPostIds.contains(post.id)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                postTypeBadge(post.postType)
                if isPinned {
                    HStack(spacing: 3) {
                        Image(systemName: "pin.fill").font(.system(size: 9))
                        Text("PINNED").font(.system(size: 9, weight: .black))
                    }
                    .foregroundColor(.lcNavy)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.lcNavy.opacity(0.1)).cornerRadius(20)
                }
                Spacer()
                Text(timeAgo(post.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(.lcText3)
            }

            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 14))
                    .foregroundColor(.lcText)
                    .lineLimit(3)
            }

            if let photoUrl = post.photoUrl, !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill().frame(height: 120).clipped().cornerRadius(8)
                    }
                }
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill").font(.system(size: 11)).foregroundColor(.lcText3)
                    Text("\(post.likeCount)").font(.system(size: 12)).foregroundColor(.lcText3)
                }

                Spacer()

                Button {
                    togglePin(post.id)
                } label: {
                    Image(systemName: isPinned ? "pin.slash" : "pin")
                        .font(.system(size: 13))
                        .foregroundColor(.lcNavy)
                        .padding(8)
                        .background(Color.lcNavy.opacity(0.08))
                        .clipShape(Circle())
                }

                Button {
                    postToDelete = post
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.08))
                        .clipShape(Circle())
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))
    }

    private func adminEventRow(_ event: Event) -> some View {
        ZStack(alignment: .topTrailing) {
            ChurchEventCard(event: event)
            Button {
                eventToDelete = event
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.12), radius: 3, y: 1)
            }
            .padding(10)
        }
    }

    private func postTypeBadge(_ type: String) -> some View {
        let (label, color): (String, Color) = {
            switch type {
            case "livestream":   return ("LIVE",         .red)
            case "event":        return ("EVENT",        .lcNavy)
            case "verse":        return ("VERSE",        .lcGold)
            case "announcement": return ("ANNOUNCE",     .orange)
            case "prayer":       return ("PRAYER",       .lcTeal)
            default:             return ("POST",         .lcText3)
            }
        }()
        return Text(label)
            .font(.system(size: 9, weight: .black))
            .foregroundColor(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(20)
    }

    // MARK: - Audience Tab

    @ViewBuilder
    private var audienceTab: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.lcNavy.opacity(0.1)).frame(width: 48, height: 48)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.lcNavy)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(followerEntries.count) \(followerEntries.count == 1 ? "follower" : "followers")")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.lcText)
                Text("People who've discovered your church")
                    .font(.system(size: 12))
                    .foregroundColor(.lcText3)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))

        if let sub = submission {
            Button {
                let slug = (sub.churchName ?? "").lowercased().replacingOccurrences(of: " ", with: "-")
                UIPasteboard.general.string = "livechurchnetwork://church/\(slug)"
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 14))
                    Text("Copy Church Profile Link").font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.lcNavy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.lcNavy.opacity(0.08))
                .cornerRadius(14)
            }
        }

        if followerEntries.isEmpty {
            emptyCard(icon: "person.2",
                      title: "No followers yet",
                      subtitle: "Share your church page to get discovered.")
        } else {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("FOLLOWERS")
                VStack(spacing: 0) {
                    ForEach(Array(followerEntries.enumerated()), id: \.element.id) { idx, entry in
                        if idx > 0 { Divider().padding(.leading, 70) }
                        NavigationLink(destination: UserProfileView(userId: entry.id)) {
                            followerRow(entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.white)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))
            }
        }
    }

    private func followerRow(_ entry: FollowEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.lcNavy).frame(width: 42, height: 42)
                if let urlStr = entry.photoUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                                .frame(width: 42, height: 42)
                                .clipShape(Circle())
                        } else {
                            followerInitials(entry.displayName)
                        }
                    }
                } else {
                    followerInitials(entry.displayName)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lcText)
                if let sub = entry.subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lcText3)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }

    private func followerInitials(_ name: String) -> some View {
        let parts = name.split(separator: " ")
        let initials = parts.count >= 2
            ? "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
            : String(name.prefix(2)).uppercased()
        return Text(initials)
            .font(.system(size: 14, weight: .black))
            .foregroundColor(.lcGold)
    }

    // MARK: - Inbox Tab

    @ViewBuilder
    private func inboxTab(_ sub: ChurchSubmission) -> some View {
        ChurchInboxView(churchName: sub.churchName ?? "")
            .frame(minHeight: 400)
    }

    // MARK: - Live Tab

    @ViewBuilder
    private func liveTab(_ sub: ChurchSubmission) -> some View {
        // Two distinct kinds of live: the admin's manual override (sub.isLive)
        // and the schedule-derived window. We show both clearly so the admin
        // never wonders why the badge is on without them tapping anything.
        let scheduledLive = LiveChurchEvaluator.isLiveNow(sub, ignoreManualOverride: true)
        let effectiveLive = sub.isLive || scheduledLive

        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(effectiveLive ? Color.red : Color.red.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: effectiveLive ? "dot.radiowaves.left.and.right" : "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(effectiveLive ? .white : .red)
            }

            Text(
                sub.isLive
                ? "You are LIVE (manual)"
                : scheduledLive
                ? "You are LIVE (scheduled)"
                : "Not currently streaming"
            )
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.lcText)

            Text(
                sub.isLive
                ? "Followers can watch your stream right now."
                : scheduledLive
                ? "Your scheduled service window is in progress — followers see the LIVE badge automatically."
                : "Tap Go Live when you want to start streaming. Your scheduled service times also light up the badge automatically."
            )
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Manual override button — only meaningful when *not* scheduled-live,
            // or when admin wants to end an unscheduled stream they started.
            if !scheduledLive || sub.isLive {
                Button { Task { await toggleLive(!sub.isLive) } } label: {
                    HStack(spacing: 8) {
                        if isTogglingLive {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: sub.isLive ? "stop.fill" : "play.fill")
                        }
                        Text(sub.isLive ? "End Livestream" : "Go Live Now")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(sub.status != "approved" ? Color.lcText3 : Color.red)
                    .cornerRadius(14)
                }
                .disabled(sub.status != "approved" || isTogglingLive)
            }

            if sub.status != "approved" {
                Text("Your church must be approved before going live.")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))

        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("STREAM URL")
            HStack(spacing: 10) {
                Image(systemName: "link")
                    .font(.system(size: 14))
                    .foregroundColor(.lcNavy)
                    .frame(width: 32, height: 32)
                    .background(Color.lcNavy.opacity(0.08))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Configure your stream URL")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.lcText)
                    Text("Add your YouTube or Vimeo URL in Settings → Edit Church Info → About")
                        .font(.system(size: 11))
                        .foregroundColor(.lcText3)
                }
                Spacer()
                Button { selectedTab = .settings } label: {
                    Image(systemName: "arrow.forward.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.lcNavy)
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))
        }

        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Notify followers when I go live")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lcText)
                Text("Push a notification to your followers when you start streaming.")
                    .font(.system(size: 11))
                    .foregroundColor(.lcText3)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { submission?.notifyFollowers ?? true },
                set: { newValue in
                    submission?.notifyFollowers = newValue
                    if let sid = submission?.id {
                        Task {
                            try? await SupabaseService.shared.updateChurchNotifyFollowers(
                                submissionId: sid, notifyFollowers: newValue)
                        }
                    }
                }
            ))
            .labelsHidden()
            .tint(.lcNavy)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))
    }

    // MARK: - Settings Tab

    @ViewBuilder
    private var settingsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("COVER PHOTO")
            VStack(spacing: 10) {
                if let coverUrl = appState.profile?.coverUrl,
                   let url = URL(string: coverUrl), !coverUrl.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(10)
                        default:
                            settingsCoverPlaceholder
                        }
                    }
                } else {
                    settingsCoverPlaceholder
                }
                PhotosPicker(selection: $coverPickerItem, matching: .images) {
                    HStack(spacing: 6) {
                        if isUploadingCover {
                            ProgressView().tint(.lcNavy).frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "photo.on.rectangle").font(.system(size: 12))
                        }
                        Text(isUploadingCover ? "Uploading..." : "Change Cover Photo")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.lcNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.lcNavy.opacity(0.08))
                    .cornerRadius(10)
                }
                .disabled(isUploadingCover)
                .onChange(of: coverPickerItem) { item in
                    Task { await handleCoverSelection(item) }
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))
        }

        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("CHURCH LOGO")
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.lcNavy.opacity(0.1)).frame(width: 64, height: 64)
                    if let photoUrl = appState.profile?.photoUrl,
                       let url = URL(string: photoUrl), !photoUrl.isEmpty {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            }
                        }
                    } else {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.lcNavy)
                    }
                }

                PhotosPicker(selection: $logoPickerItem, matching: .images) {
                    HStack(spacing: 6) {
                        if isUploadingLogo {
                            ProgressView().tint(.lcNavy).frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "photo").font(.system(size: 12))
                        }
                        Text(isUploadingLogo ? "Uploading..." : "Change Logo")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.lcNavy)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.lcNavy.opacity(0.08))
                    .cornerRadius(10)
                }
                .disabled(isUploadingLogo)
                .onChange(of: logoPickerItem) { item in
                    Task { await handleLogoSelection(item) }
                }

                Spacer()
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))
        }

        if let err = uploadError {
            Text(err)
                .font(.system(size: 12))
                .foregroundColor(.red)
                .padding(.horizontal, 14)
        }

        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("CHURCH INFORMATION")
            Button { showEditSheet = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.lcNavy)
                        .frame(width: 32, height: 32)
                        .background(Color.lcNavy.opacity(0.08))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Edit Church Info")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.lcText)
                        Text("Name, denomination, contact, services, about")
                            .font(.system(size: 11))
                            .foregroundColor(.lcText3)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.lcText3)
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }

        Button { showSignOutAlert = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14))
                Text("Sign Out")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.08))
            .cornerRadius(14)
        }
        .padding(.top, 8)
    }

    private var settingsCoverPlaceholder: some View {
        ZStack {
            defaultCoverGradient
            Image(systemName: "photo")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(height: 120)
        .cornerRadius(10)
    }

    // MARK: - Reusable pieces

    private func compactPostRow(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(post.content ?? "")
                .font(.system(size: 13))
                .foregroundColor(.lcText)
                .lineLimit(2)
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill").font(.system(size: 10)).foregroundColor(.lcText3)
                    Text("\(post.likeCount)").font(.system(size: 11)).foregroundColor(.lcText3)
                }
                Text(timeAgo(post.createdAt)).font(.system(size: 11)).foregroundColor(.lcText3)
            }
        }
        .padding(14)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.lcText3)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func emptyCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.lcNavy.opacity(0.2))
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.lcText)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))
    }

    private var noSubmissionState: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2")
                .font(.system(size: 40))
                .foregroundColor(.lcText3)
            Text("No church profile found")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lcText)
            Text("Contact support to set up your church profile.")
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Helpers

    private func statusInfo(_ status: String?) -> (String, Color) {
        switch status {
        case "approved": return ("APPROVED", .green)
        case "pending":  return ("PENDING", .orange)
        case "rejected": return ("REJECTED", .red)
        default:         return ("UNKNOWN", .lcText3)
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        switch diff {
        case ..<60:     return "now"
        case ..<3600:   return "\(Int(diff/60))m ago"
        case ..<86400:  return "\(Int(diff/3600))h ago"
        default:        return "\(Int(diff/86400))d ago"
        }
    }

    private func togglePin(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if pinnedPostIds.contains(id) {
                pinnedPostIds.remove(id)
            } else {
                pinnedPostIds.insert(id)
            }
        }
    }

    private func makePreviewChurch(from sub: ChurchSubmission) -> Church {
        Church(
            name: sub.churchName ?? "",
            slug: (sub.churchName ?? "").lowercased().replacingOccurrences(of: " ", with: "-"),
            image: appState.profile?.photoUrl ?? "",
            denomination: sub.denomination ?? "",
            permalink: "",
            phone: sub.phone ?? "",
            website: sub.website ?? "",
            serviceTimes: sub.serviceTimes ?? "",
            about: sub.about ?? "",
            isLive: sub.isLive
        )
    }

    // MARK: - Data

    private func loadAll() async {
        guard let userId = appState.currentUserId else { isLoading = false; return }

        do {
            submission = try await SupabaseService.shared.getChurchSubmission(userId: userId)
        } catch {
            print("Load submission error: \(error)")
        }

        let churchName = submission?.churchName ?? appState.profile?.fullName ?? ""
        // Churches are followed by slug, not by user_id — use the
        // church-aware lookup. Same slug computation `churchSlug()` used
        // by the web app + every FollowButton call site.
        let churchSlug = churchName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")

        async let postsTask     = SupabaseService.shared.getPostsByAuthor(authorName: churchName)
        async let eventsTask    = SupabaseService.shared.getEventsByAuthor(authorName: churchName)
        async let followersTask = SupabaseService.shared.getChurchFollowers(slug: churchSlug)
        async let inquiriesTask = SupabaseService.shared.getInquiries(churchName: churchName)

        posts     = (try? await postsTask) ?? []
        events    = (try? await eventsTask) ?? []
        inquiries = (try? await inquiriesTask) ?? []

        let rawFollowers = (try? await followersTask) ?? []
        let followerIds = rawFollowers.map { $0.followerId }
        if followerIds.isEmpty {
            followerEntries = []
        } else {
            let profiles = (try? await SupabaseService.shared.getProfiles(ids: followerIds)) ?? []
            let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
            followerEntries = followerIds.map { id in
                if let p = profileMap[id] {
                    return FollowEntry(
                        id: id,
                        displayName: p.fullName ?? "LCN Member",
                        photoUrl: p.photoUrl,
                        subtitle: p.denomination ?? p.city
                    )
                }
                return FollowEntry(id: id, displayName: "LCN Member", photoUrl: nil, subtitle: nil)
            }
        }

        isLoading = false
    }

    private func reload() async {
        let churchName = submission?.churchName ?? appState.profile?.fullName ?? ""
        async let postsTask     = SupabaseService.shared.getPostsByAuthor(authorName: churchName)
        async let eventsTask    = SupabaseService.shared.getEventsByAuthor(authorName: churchName)
        async let inquiriesTask = SupabaseService.shared.getInquiries(churchName: churchName)
        posts     = (try? await postsTask) ?? []
        events    = (try? await eventsTask) ?? []
        inquiries = (try? await inquiriesTask) ?? []
    }

    private func toggleLive(_ newValue: Bool) async {
        guard let sub = submission else { return }
        isTogglingLive = true
        do {
            try await SupabaseService.shared.updateLiveStatus(submissionId: sub.id, isLive: newValue)
            submission?.isLive = newValue
        } catch {
            uploadError = "Could not update live status."
        }
        isTogglingLive = false
    }

    private func deletePost(_ post: Post) async {
        do {
            try await SupabaseService.shared.deletePost(postId: post.id)
            posts.removeAll { $0.id == post.id }
            pinnedPostIds.remove(post.id)
        } catch {
            print("Delete post error: \(error)")
        }
        postToDelete = nil
    }

    private func deleteEvent(_ event: Event) async {
        do {
            try await SupabaseService.shared.deleteEvent(eventId: event.id)
            events.removeAll { $0.id == event.id }
        } catch {
            print("Delete event error: \(error)")
        }
        eventToDelete = nil
    }

    // MARK: - Image uploads

    private enum ImageKind {
        case cover, logo
        var bucket: String { self == .cover ? "covers" : "avatars" }
        var errorLabel: String { self == .cover ? "Cover" : "Logo" }
    }

    private func handleCoverSelection(_ item: PhotosPickerItem?) async {
        await uploadProfileImage(item, kind: .cover)
    }

    private func handleLogoSelection(_ item: PhotosPickerItem?) async {
        await uploadProfileImage(item, kind: .logo)
    }

    private func uploadProfileImage(_ item: PhotosPickerItem?, kind: ImageKind) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let compressed = UIImage(data: data)?.jpegData(compressionQuality: 0.72),
              let userId = appState.currentUserId else { return }
        switch kind {
        case .cover: isUploadingCover = true
        case .logo:  isUploadingLogo = true
        }
        uploadError = nil
        do {
            let url = try await SupabaseService.shared.uploadProfileImage(
                userId: userId, data: compressed, bucket: kind.bucket)
            // Write to the profile (drives the dashboard/feed avatar) AND to the
            // church_submissions row (drives the Discover directory image). The
            // directory reads the per-church avatar_url/cover_url, so the church
            // record must be updated too or an admin's logo won't appear there.
            switch kind {
            case .cover:
                try await SupabaseService.shared.updateProfileCoverUrl(userId: userId, coverUrl: url)
                if let sid = submission?.id {
                    try await SupabaseService.shared.updateChurchCoverUrl(submissionId: sid, coverUrl: url)
                    submission?.coverUrl = url
                }
            case .logo:
                try await SupabaseService.shared.updateProfilePhotoUrl(userId: userId, photoUrl: url)
                if let sid = submission?.id {
                    try await SupabaseService.shared.updateChurchAvatarUrl(submissionId: sid, avatarUrl: url)
                    submission?.avatarUrl = url
                }
            }
            await appState.loadProfile()
        } catch {
            uploadError = "\(kind.errorLabel) upload failed: \(error.localizedDescription)"
        }
        switch kind {
        case .cover: isUploadingCover = false
        case .logo:  isUploadingLogo = false
        }
    }
}

// MARK: - Edit church profile sheet

struct EditChurchProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let submission: ChurchSubmission
    let onSave: (ChurchSubmission) -> Void

    @State private var churchName: String
    @State private var denomination: String
    @State private var phone: String
    @State private var website: String
    @State private var serviceTimes: String
    @State private var about: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    // Structured schedule — hydrated from JSONB or the legacy text parser.
    @State private var serviceTimesJson: [ServiceTime]
    @State private var officeHoursJson: OfficeHours
    @State private var livestreamScheduleJson: LivestreamSchedule

    // Outreach + contact (each row in the Smart Recommendations card on the
    // dashboard routes here, so every recommended field has to be editable).
    @State private var contactEmail: String
    @State private var donationUrl: String
    @State private var livestreamUrl: String
    @State private var addressLine: String
    @State private var city: String
    @State private var state: String
    @State private var postalCode: String
    @State private var country: String
    @State private var pastorName: String
    @State private var whatToExpect: String
    @State private var ministries: String
    @State private var facebookUrl: String
    @State private var instagramUrl: String
    @State private var youtubeUrl: String
    @State private var tiktokUrl: String
    @State private var xUrl: String

    init(submission: ChurchSubmission, onSave: @escaping (ChurchSubmission) -> Void) {
        self.submission = submission
        self.onSave = onSave
        _churchName    = State(initialValue: submission.churchName ?? "")
        _denomination  = State(initialValue: submission.denomination ?? "")
        _phone         = State(initialValue: submission.phone ?? "")
        _website       = State(initialValue: submission.website ?? "")
        _serviceTimes  = State(initialValue: submission.serviceTimes ?? "")
        _about         = State(initialValue: submission.about ?? "")

        _contactEmail   = State(initialValue: submission.contactEmail ?? "")
        _donationUrl    = State(initialValue: submission.donationUrl ?? "")
        _livestreamUrl  = State(initialValue: submission.livestreamUrl ?? "")
        _addressLine    = State(initialValue: submission.addressLine ?? "")
        _city           = State(initialValue: submission.city ?? "")
        _state          = State(initialValue: submission.state ?? "")
        _postalCode     = State(initialValue: submission.postalCode ?? "")
        _country        = State(initialValue: submission.country ?? "")
        _pastorName     = State(initialValue: submission.pastorName ?? "")
        _whatToExpect   = State(initialValue: submission.whatToExpect ?? "")
        _ministries     = State(initialValue: submission.ministries ?? "")
        _facebookUrl    = State(initialValue: submission.facebookUrl ?? "")
        _instagramUrl   = State(initialValue: submission.instagramUrl ?? "")
        _youtubeUrl     = State(initialValue: submission.youtubeUrl ?? "")
        _tiktokUrl      = State(initialValue: submission.tiktokUrl ?? "")
        _xUrl           = State(initialValue: submission.xUrl ?? "")

        // Prefer structured JSON; fall back to parsing the legacy text.
        let structured: [ServiceTime]
        if let s = submission.serviceTimesJson, !s.isEmpty {
            structured = s
        } else {
            structured = ScheduleHelpers.parseLegacyServiceTimes(submission.serviceTimes)
        }
        _serviceTimesJson = State(initialValue: structured)
        _officeHoursJson = State(initialValue: submission.officeHoursJson ?? ScheduleHelpers.emptyOfficeHours)
        _livestreamScheduleJson = State(initialValue: submission.livestreamScheduleJson ?? ScheduleHelpers.emptyLivestreamSchedule)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Church Info") {
                    LabeledContent("Name") {
                        TextField("Church name", text: $churchName)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Denomination") {
                        TextField("e.g. Baptist", text: $denomination)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section("Contact") {
                    LabeledContent("Phone") {
                        TextField("(555) 000-0000", text: $phone)
                            .keyboardType(.phonePad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Email") {
                        TextField("hello@church.org", text: $contactEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Website") {
                        TextField("https://...", text: $website)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Pastor") {
                        TextField("Pastor name", text: $pastorName)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section("Location") {
                    TextField("Address", text: $addressLine)
                    HStack {
                        TextField("City", text: $city)
                        TextField("State", text: $state)
                            .frame(maxWidth: 80)
                    }
                    HStack {
                        TextField("Postal code", text: $postalCode)
                            .keyboardType(.numbersAndPunctuation)
                        TextField("Country", text: $country)
                    }
                }
                Section {
                    LabeledContent("Livestream URL") {
                        TextField("https://youtube.com/...", text: $livestreamUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Donation URL") {
                        TextField("https://give...", text: $donationUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Outreach")
                } footer: {
                    Text("A livestream URL unlocks the Go Live toggle. A donation link adds a Give button to your public profile.")
                }
                Section("Social Links") {
                    socialField(label: "Facebook",  text: $facebookUrl,  placeholder: "https://facebook.com/...")
                    socialField(label: "Instagram", text: $instagramUrl, placeholder: "https://instagram.com/...")
                    socialField(label: "YouTube",   text: $youtubeUrl,   placeholder: "https://youtube.com/...")
                    socialField(label: "TikTok",    text: $tiktokUrl,    placeholder: "https://tiktok.com/@...")
                    socialField(label: "X",         text: $xUrl,         placeholder: "https://x.com/...")
                }
                Section("Service Times") {
                    ServiceTimesEditor(services: $serviceTimesJson)
                        .padding(.vertical, 4)
                }
                Section("Office Hours") {
                    OfficeHoursEditor(hours: $officeHoursJson)
                        .padding(.vertical, 4)
                }
                Section {
                    LivestreamScheduleEditor(schedule: $livestreamScheduleJson)
                        .padding(.vertical, 4)
                } header: {
                    Text("Livestream Schedule")
                } footer: {
                    Text("Days and times you broadcast live online. Your church shows a LIVE badge during these windows — independent of in-person service times.")
                }
                Section("About") {
                    TextEditor(text: $about)
                        .frame(minHeight: 80)
                }
                Section("What to Expect") {
                    TextEditor(text: $whatToExpect)
                        .frame(minHeight: 60)
                }
                Section {
                    TextEditor(text: $ministries)
                        .frame(minHeight: 50)
                } header: {
                    Text("Ministries")
                } footer: {
                    Text("Comma-separated list — appears as chips on your public profile.")
                }
                if let error = errorMessage {
                    Section {
                        Text(error).foregroundColor(.red).font(.system(size: 13))
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .bold()
                        .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil

        // Re-derive the legacy text summary so external readers (older
        // clients, integrations) stay current with the structured data.
        let derivedServiceTimesText = ScheduleHelpers.summarizeServiceTimes(serviceTimesJson)

        do {
            // Step 1 — basic profile fields (name, denomination, phone,
            // website, service-times text summary, about).
            try await SupabaseService.shared.updateChurchProfile(
                submissionId: submission.id,
                churchName: churchName,
                denomination: denomination,
                phone: phone,
                website: website,
                serviceTimes: derivedServiceTimesText,
                about: about
            )
            // Step 2 — outreach + contact + location + social. Empty
            // strings are still sent so the user can clear a field.
            // Geocode the address fields BEFORE the update so the row
            // lands in church_submissions with lat/lng populated — that's
            // what the Discover "Near You" radius filter requires.
            let coords = await Geocoder.geocode(
                addressLine: addressLine, city: city, state: state,
                postalCode: postalCode, country: country
            )
            try await SupabaseService.shared.updateChurchDetails(
                submissionId: submission.id,
                contactEmail: contactEmail,
                donationUrl: donationUrl,
                livestreamUrl: livestreamUrl,
                addressLine: addressLine,
                city: city,
                state: state,
                postalCode: postalCode,
                country: country,
                latitude: coords?.latitude,
                longitude: coords?.longitude,
                pastorName: pastorName,
                whatToExpect: whatToExpect,
                ministries: ministries,
                facebookUrl: facebookUrl,
                instagramUrl: instagramUrl,
                tiktokUrl: tiktokUrl,
                xUrl: xUrl,
                youtubeUrl: youtubeUrl
            )
            // Step 3 — structured schedule (writes both JSON columns + the
            // legacy text summaries). Defensive: if the migration wasn't
            // applied, this throws; the saves above have already landed.
            try await SupabaseService.shared.updateChurchSchedule(
                submissionId: submission.id,
                services: serviceTimesJson,
                officeHours: officeHoursJson,
                livestreamSchedule: livestreamScheduleJson
            )

            var updated = submission
            updated.churchName       = churchName
            updated.denomination     = denomination
            updated.phone            = phone
            updated.website          = website
            updated.serviceTimes     = derivedServiceTimesText
            updated.about            = about
            updated.contactEmail     = contactEmail
            updated.donationUrl      = donationUrl
            updated.livestreamUrl    = livestreamUrl
            updated.addressLine      = addressLine
            updated.city             = city
            updated.state            = state
            updated.postalCode       = postalCode
            updated.country          = country
            updated.pastorName       = pastorName
            updated.whatToExpect     = whatToExpect
            updated.ministries       = ministries
            updated.facebookUrl      = facebookUrl
            updated.instagramUrl     = instagramUrl
            updated.youtubeUrl       = youtubeUrl
            updated.tiktokUrl        = tiktokUrl
            updated.xUrl             = xUrl
            updated.serviceTimesJson = serviceTimesJson
            updated.officeHoursJson  = officeHoursJson
            updated.livestreamScheduleJson = livestreamScheduleJson
            updated.officeHours      = ScheduleHelpers.summarizeOfficeHours(officeHoursJson)
            onSave(updated)
            dismiss()
        } catch {
            errorMessage = "Could not save changes. Please try again."
        }
        isSaving = false
    }

    /// Compact labeled URL-style field used for each of the 5 social network
    /// rows so the form stays scannable.
    @ViewBuilder
    private func socialField(label: String, text: Binding<String>, placeholder: String) -> some View {
        LabeledContent(label) {
            TextField(placeholder, text: text)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .multilineTextAlignment(.trailing)
        }
    }
}
