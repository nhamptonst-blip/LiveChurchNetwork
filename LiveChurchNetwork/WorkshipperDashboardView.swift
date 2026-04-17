import SwiftUI

struct WorkshipperDashboardView: View {
    @EnvironmentObject var appState: AppState

    @State private var followerCount = 0
    @State private var followingCount = 0
    @State private var userPosts: [Post] = []
    @State private var showSignOutAlert = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // HEADER with buttons
                HStack {
                    Text("My Profile")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.lcText)
                    Spacer()
                    HStack(spacing: 8) {
                        NavigationLink(destination: CreatePostView(onPosted: { Task { await loadStats(); await loadUserPosts() } }).environmentObject(appState)) {
                            Text("Post")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.lcNavy)
                                .cornerRadius(6)
                        }
                        Button { showEditProfile = true } label: {
                            Text("Edit Profile")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.lcGold)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                // SCROLLABLE CONTENT - Simple flat list
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // PROFILE CARD
                        VStack(spacing: 0) {
                            // Cover
                            ZStack {
                                if let coverUrl = appState.profile?.coverUrl, let url = URL(string: coverUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img.resizable().scaledToFill()
                                        default:
                                            LinearGradient(colors: [.lcNavy, .lcNavyDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        }
                                    }
                                } else {
                                    LinearGradient(colors: [.lcNavy, .lcNavyDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                                }
                            }
                            .frame(height: 120)
                            .clipped()

                            VStack(spacing: 0) {
                                // Avatar
                                HStack(spacing: 0) {
                                    if let photoUrl = appState.profile?.photoUrl, let url = URL(string: photoUrl) {
                                        AsyncImage(url: url) { phase in
                                            if case .success(let img) = phase {
                                                img.resizable().scaledToFill()
                                                    .frame(width: 56, height: 56)
                                                    .clipShape(Circle())
                                            } else {
                                                avatarFallback
                                            }
                                        }
                                    } else {
                                        avatarFallback
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .offset(y: -28)
                                .padding(.bottom, -28)

                                // Info
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(appState.profile?.fullName ?? "Unknown")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.lcText)

                                    if let bio = appState.profile?.bio, !bio.isEmpty {
                                        Text(bio)
                                            .font(.system(size: 13))
                                            .foregroundColor(.lcText2)
                                            .lineLimit(3)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 16)

                                // Stats
                                HStack(spacing: 24) {
                                    VStack(spacing: 4) {
                                        Text("\(followerCount)")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.lcText)
                                        Text("Followers")
                                            .font(.system(size: 11))
                                            .foregroundColor(.lcText3)
                                    }
                                    VStack(spacing: 4) {
                                        Text("\(followingCount)")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.lcText)
                                        Text("Following")
                                            .font(.system(size: 11))
                                            .foregroundColor(.lcText3)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)

                                // Sign Out
                                Button(action: { showSignOutAlert = true }) {
                                    Text("Sign Out")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(6)
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
                            .background(Color.white)
                        }
                        .cornerRadius(12)

                        // YOUR POSTS SECTION
                        if !userPosts.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Posts")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.lcText3)
                                    .padding(.horizontal, 16)

                                // ONLY render posts from current user
                                let filteredForRender = userPosts.filter { $0.authorId == appState.currentUserId }

                                ForEach(filteredForRender, id: \.id) { post in
                                    // Log every post being rendered
                                    let _ = print("""
                                    [RENDER POST]
                                    ID: \(post.id)
                                    Author ID: \(post.authorId)
                                    Author Name: \(post.authorName)
                                    Author Type: \(post.authorType)
                                    Content: \(post.content ?? "nil")
                                    Photo URL: \(post.photoUrl ?? "nil")
                                    Post Type: \(post.postType)
                                    ---
                                    """)
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 10) {
                                            Circle()
                                                .fill(Color.lcNavy)
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Text(post.authorName.prefix(1).uppercased())
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.white)
                                                )
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(post.authorName)
                                                    .font(.system(size: 14, weight: .bold))
                                                Text("1h ago")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.lcText3)
                                            }
                                            Spacer()
                                        }

                                        if let content = post.content, !content.isEmpty {
                                            Text(content)
                                                .font(.system(size: 14))
                                                .foregroundColor(.lcText)
                                        }

                                        if let photoUrl = post.photoUrl, !photoUrl.isEmpty {
                                            AsyncImage(url: URL(string: photoUrl)) { phase in
                                                if case .success(let img) = phase {
                                                    img.resizable().scaledToFill()
                                                } else {
                                                    Color.lcBorder
                                                }
                                            }
                                            .frame(height: 200)
                                            .clipped()
                                            .cornerRadius(8)
                                        }
                                    }
                                    .padding(14)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .padding(.horizontal, 16)
                                }
                            }
                        }

                        Spacer()
                            .frame(height: 24)
                    }
                    .padding(.vertical, 16)
                }
            }
            .background(Color.lcCream)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEditProfile) {
                if let profile = appState.profile, let userId = appState.currentUserId {
                    EditWorshipperProfileView(profile: profile, userId: userId) {
                        Task { await appState.loadProfile() }
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { await appState.signOut() }
                }
            } message: {
                Text("Are you sure?")
            }
        }
        .task {
            await loadStats()
            await loadUserPosts()
        }
    }

    private var avatarFallback: some View {
        ZStack {
            Circle()
                .fill(Color.lcNavy)
                .frame(width: 56, height: 56)
            Text((appState.profile?.fullName ?? "U").prefix(1).uppercased())
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.lcGold)
        }
    }

    private func loadStats() async {
        guard let userId = appState.currentUserId else { return }

        do {
            let followers = try await SupabaseService.shared.getFollowers(userId: userId)
            followerCount = followers.count

            let following = try await SupabaseService.shared.getFollowing(followerId: userId)
            followingCount = following.count
        } catch {
            print("Load stats error: \(error)")
        }
    }

    private func loadUserPosts() async {
        guard let userId = appState.currentUserId else { return }

        do {
            let posts = try await SupabaseService.shared.getUserPosts(userId: userId)
            await MainActor.run {
                userPosts = posts.sorted { $0.createdAt > $1.createdAt }
            }
        } catch {
            print("Load user posts error: \(error)")
        }
    }
}
