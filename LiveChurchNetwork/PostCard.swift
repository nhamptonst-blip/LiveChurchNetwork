import SwiftUI

struct PostCard: View {
    let post: Post
    var onLikeToggled: ((Post) -> Void)?

    @EnvironmentObject var appState: AppState
    @State private var isLiking = false
    @State private var showPostDetail = false

    private var timeAgo: String {
        let diff = Date().timeIntervalSince(post.createdAt)
        switch diff {
        case ..<60:       return "just now"
        case ..<3600:     return "\(Int(diff/60))m ago"
        case ..<86400:    return "\(Int(diff/3600))h ago"
        default:          return "\(Int(diff/86400))d ago"
        }
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                header

                // Type-specific content rendering
                switch post.postType {
                case "verse":
                    verseCard
                case "announcement":
                    announcementCard
                    if let photoUrl = post.photoUrl, !photoUrl.isEmpty {
                        photoView(photoUrl)
                    }
                case "prayer":
                    prayerCard
                default:
                    if let content = post.content, !content.isEmpty {
                        Text(content)
                            .font(.system(size: 15))
                            .foregroundColor(.lcText)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                    }
                    if let photoUrl = post.photoUrl, !photoUrl.isEmpty {
                        photoView(photoUrl)
                    }
                    if let videoUrl = post.videoUrl, !videoUrl.isEmpty {
                        videoLinkView(videoUrl)
                    }
                }

                actions
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(post.isImportant ? Color.yellow.opacity(0.7) : Color.clear, lineWidth: 1.5)
            )
            .padding(.vertical, 2)

            NavigationLink(isActive: $showPostDetail) {
                PostDetailView(post: post)
            } label: {
                EmptyView()
            }
            .hidden()
        }
        .onTapGesture {
            showPostDetail = true
        }
    }

    // MARK: Header helpers

    private var authorSeedUser: DiscoverableUser? {
        guard post.authorType == "worshipper" else { return nil }
        return MockDataProvider.allSeedUsers.first { $0.id == post.authorId }
    }

    private var authorChurch: Church? {
        guard post.authorType == "church" else { return nil }
        guard let submission = appState.church(byName: post.authorName) else { return nil }
        return appState.toChurch(submission)
    }

    /// One-line sublabel shown beneath the author name.
    /// Church: denomination (or "Church") · time
    /// User:   city (if known) · time
    private var authorSublabel: String {
        if post.authorType == "church" {
            let denom = authorChurch?.denomination ?? ""
            let label = denom.isEmpty ? "Church" : denom
            return "\(label) · \(timeAgo)"
        } else {
            let city = authorSeedUser?.city ?? ""
            return city.isEmpty ? timeAgo : "\(city) · \(timeAgo)"
        }
    }

    /// Photo URL for the post author — seed data, current user's profile, or nil.
    private var authorPhotoUrl: String? {
        if let seed = authorSeedUser { return seed.photoUrl }
        if post.authorId == appState.currentUserId { return appState.profile?.photoUrl }
        return nil
    }

    private var authorIdentity: some View {
        HStack(spacing: 10) {
            // ── Avatar ──────────────────────────────────────────────────
            if let seedUser = authorSeedUser {
                UserAvatarView(user: seedUser, size: .feed)
            } else if post.authorType == "worshipper", let photoUrl = authorPhotoUrl,
                      let url = URL(string: photoUrl) {
                // Real Supabase user with a profile photo
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                    } else {
                        authorInitialsCircle
                    }
                }
                .frame(width: 42, height: 42)
                .clipShape(Circle())
            } else if let church = authorChurch {
                // Church: rounded-square with church image
                AsyncImage(url: URL(string: church.image)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        Color.lcNavy
                            .overlay(
                                Text(post.authorName.prefix(1).uppercased())
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(.lcGold)
                            )
                    }
                }
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            } else {
                authorInitialsCircle
            }

            // ── Name + sublabel ──────────────────────────────────────────
            authorIdentityNameStack
        }
    }

    private var authorInitialsCircle: some View {
        let parts = post.authorName.split(separator: " ")
        let initials = parts.count >= 2
            ? "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
            : post.authorName.prefix(2).uppercased()
        return ZStack {
            Circle().fill(Color.lcNavy).frame(width: 42, height: 42)
            Text(String(initials))
                .font(.system(size: 15, weight: .black))
                .foregroundColor(.lcGold)
        }
    }

    private var authorIdentityNameStack: some View {
        // ── Name + sublabel ──────────────────────────────────────────
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(post.authorName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lcText)
                postTypeBadge
            }
            HStack(spacing: 6) {
                Text(authorSublabel)
                    .font(.system(size: 11))
                    .foregroundColor(.lcText3)
                if post.isImportant {
                    HStack(spacing: 3) {
                        Text("⚡")
                        Text("Important")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(12)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            if post.authorType == "worshipper" {
                NavigationLink(destination: UserProfileView(userId: post.authorId)) {
                    authorIdentity
                }
                .buttonStyle(.plain)
            } else if post.authorType == "church", let church = authorChurch {
                NavigationLink(destination: ChurchDetailView(church: church)) {
                    authorIdentity
                }
                .buttonStyle(.plain)
            } else {
                authorIdentity
            }

            Spacer()

            if post.authorType == "church" {
                // Use church slug from appState if available, otherwise generate from name
                let churchSlug = authorChurch?.slug ?? post.authorName.lowercased().replacingOccurrences(of: " ", with: "-")
                FollowButton(followingId: churchSlug, followingType: "church", initialIsFollowing: false)
            } else if post.authorType == "worshipper" && post.authorId != appState.currentUserId {
                FollowButton(followingId: post.authorId.uuidString, followingType: "worshipper", initialIsFollowing: false)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 4)
    }

    // MARK: Post type badge

    @ViewBuilder
    private var postTypeBadge: some View {
        switch post.postType {
        case "livestream":
            HStack(spacing: 3) {
                Circle().fill(Color.red).frame(width: 5, height: 5)
                Text("LIVE").font(.system(size: 9, weight: .black)).foregroundColor(.red)
            }
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.red.opacity(0.1)).cornerRadius(20)
        case "event":
            Text("EVENT")
                .font(.system(size: 9, weight: .black)).foregroundColor(.lcNavy)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.lcNavy.opacity(0.1)).cornerRadius(20)
        case "verse":
            Text("VERSE")
                .font(.system(size: 9, weight: .black)).foregroundColor(.lcGold)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.lcGold.opacity(0.15)).cornerRadius(20)
        case "announcement":
            Text("ANNOUNCEMENT")
                .font(.system(size: 9, weight: .black)).foregroundColor(.orange)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.orange.opacity(0.1)).cornerRadius(20)
        case "prayer":
            Text("PRAYER")
                .font(.system(size: 9, weight: .black)).foregroundColor(.lcTeal)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.lcTeal.opacity(0.1)).cornerRadius(20)
        default:
            EmptyView()
        }
    }

    // MARK: Verse card

    private var verseCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Extract scripture reference (first line before double newline)
            let scriptureRef = post.content?.components(separatedBy: "\n\n").first ?? ""

            HStack(spacing: 6) {
                Image(systemName: "book.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.lcGold)
                if !scriptureRef.isEmpty {
                    Text(scriptureRef)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.lcGold)
                }
            }
            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 16, weight: .medium))
                    .italic()
                    .foregroundColor(.lcText)
                    .lineSpacing(4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lcGoldLight)
        .cornerRadius(12)
        .overlay(
            HStack(spacing: 0) {
                Rectangle().fill(Color.lcGold).frame(width: 3)
                Spacer()
            }
            .cornerRadius(12)
        )
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: Announcement card

    private var announcementCard: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle().fill(Color.lcGold).frame(width: 3)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                    Text("Announcement")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                }
                if let content = post.content, !content.isEmpty {
                    Text(content)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.lcText)
                }
            }
            .padding(12)
        }
        .background(Color.orange.opacity(0.04))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: Prayer card

    private var prayerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.lcTeal)
                Text("Prayer Request")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.lcTeal)
            }
            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lcTeal.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: Photo

    private func photoView(_ urlString: String) -> some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .success(let img):
                img.resizable().scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
            case .failure:
                EmptyView()
            default:
                Rectangle().fill(Color.lcBorder).frame(height: 220)
                    .overlay(ProgressView().tint(.lcNavy))
            }
        }
        .padding(.top, 10)
    }

    // MARK: Video link

    private func videoLinkView(_ urlString: String) -> some View {
        Link(destination: URL(string: urlString) ?? URL(string: "https://youtube.com")!) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red)
                        .frame(width: 44, height: 44)
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Watch Video")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.lcText)
                    Text(urlString)
                        .font(.system(size: 11))
                        .foregroundColor(.lcText3)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11))
                    .foregroundColor(.lcText3)
            }
            .padding(12)
            .background(Color.lcCream)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }

    // MARK: Actions

    private var actions: some View {
        HStack(spacing: 20) {
            Button {
                guard let userId = appState.currentUserId else { return }
                HapticEngine.impact(.light)
                Task { await toggleLike(userId: userId) }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(post.isLiked ? .red : .lcText3)
                        .scaleEffect(post.isLiked ? 1.15 : 1.0)
                        .animation(.appSpring, value: post.isLiked)
                    if post.likeCount > 0 {
                        Text("\(post.likeCount)")
                            .font(.system(size: 13))
                            .foregroundColor(.lcText3)
                    }
                }
            }
            .disabled(isLiking)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: Like action

    private func toggleLike(userId: UUID) async {
        isLiking = true
        var updated = post
        do {
            if post.isLiked {
                try await SupabaseService.shared.unlikePost(userId: userId, postId: post.id, currentCount: post.likeCount)
                updated.isLiked = false
                updated.likeCount = max(0, post.likeCount - 1)
            } else {
                try await SupabaseService.shared.likePost(userId: userId, postId: post.id, currentCount: post.likeCount)
                updated.isLiked = true
                updated.likeCount = post.likeCount + 1
            }
            onLikeToggled?(updated)
        } catch {
            print("Like error: \(error)")
        }
        isLiking = false
    }
}
