import SwiftUI

struct WorkshipperDashboardView: View {
    @EnvironmentObject var appState: AppState

    @State private var followerCount = 0
    @State private var followingCount = 0
    @State private var userPosts: [Post] = []
    @State private var isLoading = true
    @State private var showSignOutAlert = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
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

                // Profile Card
                ScrollView {
                    VStack(spacing: 0) {
                        // Cover or gradient
                        ZStack {
                            if let coverUrl = appState.profile?.coverUrl, let url = URL(string: coverUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable().scaledToFill()
                                    default:
                                        defaultCover
                                    }
                                }
                            } else {
                                defaultCover
                            }
                        }
                        .frame(height: 120)
                        .clipped()

                        VStack(spacing: 0) {
                            // Avatar
                            HStack(spacing: 0) {
                                if let photoUrl = appState.profile?.photoUrl, let url = URL(string: photoUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img.resizable().scaledToFill()
                                                .frame(width: 56, height: 56)
                                                .clipShape(Circle())
                                        default:
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)

                    // TEST: Temporarily showing raw list of userPosts to debug
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DEBUG - Posts in array: \(userPosts.count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .padding(.horizontal, 16)

                        ForEach(userPosts, id: \.id) { post in
                            Text("• \(post.authorName): \(post.content?.prefix(30) ?? "no content")")
                                .font(.system(size: 11))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 24)

                    Text("END OF PROFILE")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                        .padding(16)
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

    private var defaultCover: some View {
        LinearGradient(colors: [.lcNavy, .lcNavyDark], startPoint: .topLeading, endPoint: .bottomTrailing)
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
        isLoading = true
        defer { isLoading = false }

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
        guard let userId = appState.currentUserId else {
            print("[WorkshipperDashboardView] No current user ID")
            return
        }

        do {
            let posts = try await SupabaseService.shared.getUserPosts(userId: userId)
            print("[WorkshipperDashboardView] ===== LOADED POSTS =====")
            print("[WorkshipperDashboardView] Current user ID: \(userId)")
            print("[WorkshipperDashboardView] Total posts returned: \(posts.count)")

            for (index, post) in posts.enumerated() {
                print("[WorkshipperDashboardView] Post \(index + 1):")
                print("[WorkshipperDashboardView]   - ID: \(post.id)")
                print("[WorkshipperDashboardView]   - Author ID: \(post.authorId)")
                print("[WorkshipperDashboardView]   - Author Name: \(post.authorName)")
                print("[WorkshipperDashboardView]   - Author Type: \(post.authorType)")
                print("[WorkshipperDashboardView]   - Content: \(post.content ?? "nil")")
                print("[WorkshipperDashboardView]   - Match? \(post.authorId == userId ? "✅ YES" : "❌ NO - WRONG USER!")")
            }
            print("[WorkshipperDashboardView] ===== END POSTS =====")

            await MainActor.run {
                print("[WorkshipperDashboardView] Setting userPosts array with \(posts.count) posts")
                userPosts = posts.sorted { $0.createdAt > $1.createdAt }
                print("[WorkshipperDashboardView] userPosts array now has \(userPosts.count) items")
            }
        } catch {
            print("Load user posts error: \(error)")
        }
    }
}
