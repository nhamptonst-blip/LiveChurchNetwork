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
                    HStack(spacing: 10) {
                        NavigationLink(destination: CreatePostView(onPosted: { Task { await loadStats(); await loadUserPosts() } }).environmentObject(appState)) {
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
                            .cornerRadius(8)
                        }
                        Button { showEditProfile = true } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Edit")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.lcGold)
                            .cornerRadius(8)
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
                            Button {
                                showSignOutAlert = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Sign Out")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .cornerRadius(8)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .background(Color.white)
                    }
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)

                    // Posts Section
                    if !userPosts.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Your Posts")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.lcText3)
                                .padding(.horizontal, 16)
                                .padding(.top, 24)
                                .padding(.bottom, 12)

                            ForEach(userPosts) { post in
                                PostCard(post: post)
                                Divider().padding(.leading, 16)
                            }
                        }
                        .padding(.bottom, 24)
                    }
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
