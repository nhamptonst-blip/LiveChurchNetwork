import SwiftUI
                                                                                                                                                                               
struct FeedView: View {
    @EnvironmentObject var appState: AppState
    @State private var posts: [Post] = []
    @State private var events: [Event] = []
    @State private var liveChurches: [ChurchSubmission] = []
    @State private var isLoading = true
    @State private var showCreatePost = false
                                                                                                                                                                               
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().tint(.lcNavy)
                } else {
                    feedList
                }
            }
            .background(Color.lcCream)
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    logoMark
                }
                if !appState.isGuest {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showCreatePost = true
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Post")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.lcNavy)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView { await loadFeed() }
            }
            .refreshable { await loadFeed() }
        }
        .task { await loadFeed() }
        .onChange(of: appState.currentUserId) { _ in
            // Re-load when auth resolves so liked states are correct
            Task { await loadFeed() }
        }
    }
                                                          
    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if !liveChurches.isEmpty { liveNowBanner }
                if !events.isEmpty { eventsStrip }
                if posts.isEmpty {
                    emptyFeed
                } else {
                    ForEach(posts) { post in
                        PostCard(post: post, onLikeToggled: { updatedPost in
                            if let idx = posts.firstIndex(where: { $0.id == updatedPost.id }) {
                                posts[idx] = updatedPost
                            }
                        })
                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
    }

    private var liveNowBanner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(liveChurches) { church in
                    HStack(spacing: 8) {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                        Text(church.churchName ?? "Church")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Text("LIVE")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.black.opacity(0.9))
    }

    private var eventsStrip: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Upcoming Events")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.lcText2)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(events) { event in
                            EventPill(event: event)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
            }
            .background(Color.white)
            Divider()
        }
    }
                                                          
    private var emptyFeed: some View {
        VStack(spacing: 14) {
            Image(systemName: "newspaper")
                .font(.system(size: 44))
                .foregroundColor(.lcText3)
                .padding(.top, 60)
            Text("Nothing in your feed yet")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lcText)
            Text("Follow churches and worshippers to see their posts here.")
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }

    private var logoMark: some View {
        HStack(spacing: 6) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .cornerRadius(5)
            Text("Live Church Network")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.lcNavy)
        }
    }
                                                          
    @MainActor
    private func loadFeed() async {
        isLoading = true
        defer { isLoading = false }

        // 1. Fetch all remote data concurrently
        async let postsTask  = SupabaseService.shared.getFeedPosts()
        async let eventsTask = SupabaseService.shared.getUpcomingEvents()
        async let liveTask   = SupabaseService.shared.getLiveChurches()

        // Await all three together so we get a complete snapshot or nothing
        var rawPosts  = (try? await postsTask)  ?? []
        let rawEvents = (try? await eventsTask) ?? []
        let rawLive   = (try? await liveTask)   ?? []

        // 2. Guard against stale results from a cancelled task
        guard !Task.isCancelled else { return }

        // 3. Fetch liked post IDs now that all other data is in hand
        if let userId = appState.currentUserId {
            let liked = (try? await SupabaseService.shared.getLikedPostIds(userId: userId)) ?? []
            for i in rawPosts.indices {
                rawPosts[i].isLiked = liked.contains(rawPosts[i].id)
            }
        }

        guard !Task.isCancelled else { return }

        // 4. Sort posts by type priority then recency
        let sorted = rawPosts.sorted { a, b in
            let priority = ["livestream": 0, "announcement": 1, "event": 2, "verse": 3, "prayer": 3, "update": 3]
            let ap = priority[a.postType] ?? 2
            let bp = priority[b.postType] ?? 2
            if ap != bp { return ap < bp }
            return a.createdAt > b.createdAt
        }

        // 5. Merge real posts with seed posts — real posts first, then seed fill
        let seedPosts = MockDataProvider.feedPosts
        let realIds   = Set(sorted.map { $0.id })
        let merged    = sorted + seedPosts.filter { !realIds.contains($0.id) }

        // 6. Single atomic state update
        posts        = merged.isEmpty    ? seedPosts                           : merged
        events       = rawEvents.isEmpty ? MockDataProvider.feedEvents         : rawEvents
        liveChurches = rawLive.isEmpty   ? MockDataProvider.liveFeedChurches  : rawLive

        print("[FeedView] Loaded — posts: \(posts.count), events: \(events.count), live: \(liveChurches.count)")
    }
}
                                                                                                                                                                               
struct EventPill: View {
    let event: Event

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f
    }()

    private var dateString: String {
        Self.dateFormatter.string(from: event.eventDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dateString)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.lcGold)
            Text(event.title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.lcText)
                .lineLimit(1)
            Text(event.authorName)
                .font(.system(size: 10))
                .foregroundColor(.lcText3)
                .lineLimit(1)
            if let location = event.location, !location.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "mappin").font(.system(size: 9))
                    Text(location).font(.system(size: 10))
                }
                .foregroundColor(.lcText3)
            }
        }
        .padding(12)
        .frame(width: 160, alignment: .leading)
        .background(Color.lcNavy.opacity(0.05))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
    }
}
 
