import SwiftUI

struct UserProfileView: View {
    let userId: UUID
    @EnvironmentObject var appState: AppState
    @State private var profile: Profile?
    @State private var isLoading = true
    @State private var followerCount = 0
    @State private var viewerFollows = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let profile = profile {
                    profileContent(profile)
                } else {
                    Text("User not found")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(Color.lcCream)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProfile()
        }
    }

    private func profileContent(_ profile: Profile) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Cover
            ZStack(alignment: .topLeading) {
                if let coverUrl = profile.coverUrl, let url = URL(string: coverUrl) {
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
                // Avatar and header
                HStack(alignment: .top, spacing: 16) {
                    if let photoUrl = profile.photoUrl, let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                avatarPlaceholder(profile.fullName ?? "U")
                            }
                        }
                    } else {
                        avatarPlaceholder(profile.fullName ?? "U")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.fullName ?? "Unknown")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.lcText)
                        Text("Member")
                            .font(.system(size: 13))
                            .foregroundColor(.lcText3)
                        if let city = profile.city, !city.isEmpty {
                            Text(city)
                                .font(.system(size: 12))
                                .foregroundColor(.lcText3)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 16)

                // Bio
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 14))
                        .foregroundColor(.lcText2)
                        .lineLimit(4)
                }

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    if let denom = profile.denomination, !denom.isEmpty {
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
                    if let church = profile.homeChurchName, !church.isEmpty {
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
                    Spacer()
                }

                Divider()
                    .padding(.vertical, 8)

                // Follow button (if not own profile)
                if appState.currentUserId != userId {
                    Button {
                        Task { await toggleFollow() }
                    } label: {
                        Text(viewerFollows ? "Following" : "Follow")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(viewerFollows ? Color.lcNavy.opacity(0.5) : Color.lcNavy)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(24)
            .background(Color.white)

            Spacer()
        }
    }

    private func avatarPlaceholder(_ initials: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.lcNavy)
                .frame(width: 80, height: 80)
            Text(initials.prefix(1).uppercased())
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.lcGold)
        }
    }

    private func loadProfile() async {
        do {
            if let profile = try await SupabaseService.shared.getProfile(userId: userId) {
                let followers = try await SupabaseService.shared.getFollowers(userId: userId)
                let isFollowing = (try? await SupabaseService.shared.isFollowingUser(
                    followerId: appState.currentUserId ?? UUID(),
                    subjectId: userId
                )) ?? false

                await MainActor.run {
                    self.profile = profile
                    self.followerCount = followers.count
                    self.viewerFollows = isFollowing
                    self.isLoading = false
                }
            }
        } catch {
            print("Error loading profile: \(error)")
            await MainActor.run { isLoading = false }
        }
    }

    private func toggleFollow() async {
        guard let currentUserId = appState.currentUserId else { return }

        do {
            if viewerFollows {
                HapticEngine.impact(.light)
                try await SupabaseService.shared.unfollow(followerId: currentUserId, followingId: userId.uuidString)
            } else {
                HapticEngine.impact(.medium)
                try await SupabaseService.shared.follow(followerId: currentUserId, followingId: userId.uuidString, followingType: "worshipper")
            }

            await MainActor.run {
                viewerFollows.toggle()
            }
        } catch {
            print("Error toggling follow: \(error)")
        }
    }
}
