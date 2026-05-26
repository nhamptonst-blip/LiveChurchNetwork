import SwiftUI

struct WorkshipperDashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var followerCount = 0
    @State private var followingCount = 0
    @State private var showEditProfile = false
    @State private var userPosts: [Post] = []
    @State private var editingPostId: UUID?
    @State private var editedContent: String = ""
    @State private var isSavingPost = false
    /// Total inquiries the worshipper has sent — drives the Messages card label.
    @State private var inquiryCount = 0
    /// Inquiries with a reply that the member hasn't opened yet — counted via
    /// unread `church_inquiry_reply` notifications, not by reading the inquiry
    /// rows directly.
    @State private var unreadReplyCount = 0
    @State private var showMessages = false

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

                            // Notification preferences — per-category opt-outs.
                            // Toggle persistence is owned by the DB-side
                            // trigger, which silently drops disabled types.
                            NavigationLink(destination: NotificationPreferencesView().environmentObject(appState)) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bell.badge")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.lcText3)
                                    Text("Notifications")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.lcText3)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.lcText3)
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)

                            // Blocked accounts (safety) — surfaced from the
                            // privacy section of every account so users have
                            // an obvious recovery path for any block.
                            NavigationLink(destination: BlockedAccountsView().environmentObject(appState)) {
                                HStack(spacing: 8) {
                                    Image(systemName: "hand.raised")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.lcText3)
                                    Text("Blocked Accounts")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.lcText3)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.lcText3)
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)

                            // Delete account — required by App Store Guideline
                            // 5.1.1(v). Uses the destructive red so the user
                            // can't miss it and the type-to-confirm gate lives
                            // inside DeleteAccountView so accidental taps are
                            // safe.
                            NavigationLink(destination: DeleteAccountView().environmentObject(appState)) {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.red)
                                    Text("Delete Account")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.red)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.red.opacity(0.6))
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)

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

                // Messages — entry point to MyInquiriesView. Shows replies
                // from churches the worshipper has reached out to. Unread
                // count comes from the notifications table so it stays
                // truthful across devices.
                Button { showMessages = true } label: {
                    HStack(spacing: 14) {
                        ZStack(alignment: .topTrailing) {
                            ZStack {
                                Circle()
                                    .fill(Color.lcNavy.opacity(0.10))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.lcNavy)
                            }
                            if unreadReplyCount > 0 {
                                Text("\(unreadReplyCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                    .offset(x: 4, y: -4)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Messages")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.lcText)
                            Text(messagesSubtitle)
                                .font(.system(size: 12))
                                .foregroundColor(.lcText3)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.lcText3)
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.lcBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
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
                            VStack(alignment: .leading, spacing: 12) {
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

                                Button(action: {
                                    editedContent = post.content ?? ""
                                    editingPostId = post.id
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 14))
                                        Text("Edit Post")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(Color.lcNavy)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .border(Color.lcBorder, width: 1)
                            .sheet(isPresented: .constant(editingPostId == post.id)) {
                                editPostSheet(post)
                            }
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
        .sheet(isPresented: $showMessages, onDismiss: {
            // Refresh the unread count after the worshipper closes Messages —
            // any inquiry they opened may have flipped its notification to read.
            Task { await loadStats() }
        }) {
            if let userId = appState.currentUserId {
                MyInquiriesView(memberId: userId)
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

    private var messagesSubtitle: String {
        if unreadReplyCount > 0 {
            return "\(unreadReplyCount) new reply\(unreadReplyCount == 1 ? "" : "s")"
        }
        if inquiryCount == 0 {
            return "Reach out to a church to start a conversation"
        }
        return "\(inquiryCount) message\(inquiryCount == 1 ? "" : "s")"
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
        // Inquiry totals + unread-reply count drive the Messages card.
        // Pulled separately from the main stats block so a single failure
        // (e.g. unmigrated reply columns on an older build) doesn't blow
        // away followers / following / posts.
        do {
            let mine = try await SupabaseService.shared.getInquiriesForMember(memberId: userId)
            let notifs = (try? await SupabaseService.shared.getNotifications(userId: userId)) ?? []
            let unread = notifs.filter { $0.type == "church_inquiry_reply" && !$0.isRead }.count
            await MainActor.run {
                inquiryCount = mine.count
                unreadReplyCount = unread
            }
        } catch {
            print("Error loading inquiries: \(error)")
        }
    }

    private func editPostSheet(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Edit Post")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.lcText)
                Spacer()
                Button("Done") {
                    editingPostId = nil
                }
                .foregroundColor(.lcNavy)
            }

            TextEditor(text: $editedContent)
                .frame(minHeight: 120)
                .font(.system(size: 14))
                .foregroundColor(.lcText)
                .padding(8)
                .background(Color.lcCream)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.lcBorder, lineWidth: 1))

            if let photoUrl = post.photoUrl, !photoUrl.isEmpty {
                AsyncImage(url: URL(string: photoUrl)) { phase in
                    if case .success(let img) = phase {
                        img.resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    editingPostId = nil
                }
                .foregroundColor(.lcNavy)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.lcNavy, lineWidth: 1.5))

                Button(action: {
                    Task { await savePost(post) }
                }) {
                    if isSavingPost {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Save Changes")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.lcNavy)
                .cornerRadius(8)
                .disabled(isSavingPost)
            }

            Spacer()
        }
        .padding(24)
        .background(Color.lcCream)
    }

    private func savePost(_ post: Post) async {
        await MainActor.run { isSavingPost = true }
        do {
            try await SupabaseService.shared.updatePost(
                postId: post.id,
                content: editedContent,
                photoUrl: post.photoUrl
            )
            await MainActor.run {
                editingPostId = nil
                isSavingPost = false
                HapticEngine.impact(.light)
            }
            await loadStats()
        } catch {
            print("Error saving post: \(error)")
            await MainActor.run { isSavingPost = false }
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
