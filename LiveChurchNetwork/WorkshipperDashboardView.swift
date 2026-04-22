import SwiftUI

struct WorkshipperDashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var followerCount = 0
    @State private var followingCount = 0
    @State private var showEditProfile = false
    @State private var userPosts: [Post] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with actions
                HStack {
                    Text("My Profile")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.lcText)
                    Spacer()
                    Button { showEditProfile = true } label: {
                        Text("Edit Profile")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.lcText3)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .border(Color.lcBorder, width: 1)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)

                // Profile card
                VStack(spacing: 0) {
                        // Cover
                        ZStack(alignment: .topLeading) {
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
                        .frame(height: 144)
                        .clipped()

                        VStack(alignment: .leading, spacing: 16) {
                            // Avatar
                            HStack(alignment: .top, spacing: 16) {
                                if let photoUrl = appState.profile?.photoUrl, let url = URL(string: photoUrl) {
                                    AsyncImage(url: url) { phase in
                                        if case .success(let img) = phase {
                                            img.resizable().scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(Circle())
                                        } else {
                                            avatarPlaceholder
                                        }
                                    }
                                } else {
                                    avatarPlaceholder
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appState.profile?.fullName ?? "Unknown")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.lcText)
                                    Text("Member")
                                        .font(.system(size: 13))
                                        .foregroundColor(.lcText3)
                                        .textCase(.lowercase)
                                    if let city = appState.profile?.city, !city.isEmpty {
                                        Text(city)
                                            .font(.system(size: 12))
                                            .foregroundColor(.lcText3)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.top, 16)

                            // Bio
                            if let bio = appState.profile?.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.system(size: 14))
                                    .foregroundColor(.lcText2)
                                    .lineLimit(4)
                            }

                            // Info section
                            VStack(alignment: .leading, spacing: 8) {
                                if let denom = appState.profile?.denomination, !denom.isEmpty {
                                    HStack(spacing: 8) {
                                        Text("DENOMINATION")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.lcText3)
                                            .tracking(0.3)
                                        Text(denom)
                                            .font(.system(size: 13))
                                            .foregroundColor(.lcText2)
                                    }
                                }
                                if let church = appState.profile?.homeChurchName, !church.isEmpty {
                                    HStack(spacing: 8) {
                                        Text("CHURCH I ATTEND")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.lcText3)
                                            .tracking(0.3)
                                        Text(church)
                                            .font(.system(size: 13))
                                            .foregroundColor(.lcText2)
                                    }
                                }
                            }

                            // Stats
                            HStack(spacing: 24) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(followerCount)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.lcText)
                                    Text(followerCount == 1 ? "follower" : "followers")
                                        .font(.system(size: 12))
                                        .foregroundColor(.lcText3)
                                }
                                NavigationLink(destination: FollowingListView(userId: appState.currentUserId).environmentObject(appState)) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(followingCount)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.lcText)
                                        Text("following")
                                            .font(.system(size: 12))
                                            .foregroundColor(.lcText3)
                                    }
                                }
                                Spacer()
                            }

                            Divider()
                                .padding(.vertical, 8)

                            // Sign out button
                            Button {
                                Task { await appState.signOut() }
                            } label: {
                                Text("Sign Out")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.lcText3)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                    }
                .cornerRadius(16)
                .border(Color.lcBorder, width: 1)
                .padding(.horizontal, 16)

                // Posts Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("My Posts")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.lcText)
                        .padding(.horizontal, 16)

                    if userPosts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 32))
                                .foregroundColor(.lcText3)
                            Text("No posts yet")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.lcText)
                            Text("Create your first post to share with followers")
                                .font(.system(size: 12))
                                .foregroundColor(.lcText3)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                    } else {
                        ForEach(userPosts, id: \.id) { post in
                            NavigationLink(destination: PostDetailView(post: post).environmentObject(appState)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.pencil")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.lcNavy)
                                        Text(post.postType.uppercased())
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.lcNavy)
                                            .tracking(0.5)
                                        Spacer()
                                    }

                                    if let content = post.content {
                                        Text(content)
                                            .font(.system(size: 13))
                                            .foregroundColor(.lcText2)
                                            .lineLimit(3)
                                    }

                                    HStack(spacing: 12) {
                                        Text("❤️ \(post.likeCount)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.lcText3)
                                        Spacer()
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .border(Color.lcBorder, width: 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
            }
            .padding(.vertical, 16)
        }
        .background(Color.lcCream)
        .onAppear {
            Task {
                await appState.loadProfile()
                await loadStats()
            }
        }
        .sheet(isPresented: $showEditProfile) {
            if let profile = appState.profile, let userId = appState.currentUserId {
                EditWorshipperProfileView(profile: profile, userId: userId) {
                    Task { await appState.loadProfile() }
                }
            }
        }
        .task {
            await appState.loadProfile()
            await loadStats()
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.lcNavy)
                .frame(width: 80, height: 80)
            Text((appState.profile?.fullName ?? "U").prefix(1).uppercased())
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.lcGold)
        }
    }

    private func loadStats() async {
        guard let userId = appState.currentUserId else { return }
        do {
            let followers = try await SupabaseService.shared.getFollowers(userId: userId)
            await MainActor.run { followerCount = followers.count }

            let following = try await SupabaseService.shared.getFollowing(followerId: userId)
            await MainActor.run { followingCount = following.count }

            let posts = try await SupabaseService.shared.getUserPosts(userId: userId)
            await MainActor.run { userPosts = posts }
        } catch {
            print("Error loading stats: \(error)")
        }
    }
}

// Placeholder for FollowingListView
struct FollowingListView: View {
    let userId: UUID?

    var body: some View {
        Text("Following")
    }
}
