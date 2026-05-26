import SwiftUI
import Supabase

/// Unified engagement stream for the church admin dashboard.
/// Merges new follows + likes + prayer_responses + comments + inquiries into
/// a single time-ordered feed. 1:1 mirror of web's
/// `src/lib/church-activity.ts` + `<ChurchActivityFeed/>` component.

enum ActivityKind: String {
    case follow, like, prayer, comment, inquiry, rsvp
}

struct ActivityItem: Identifiable, Hashable {
    let id: String
    let kind: ActivityKind
    let actorId: String?
    let actorName: String
    let actorPhotoUrl: String?
    let message: String
    let target: String?
    let createdAt: Date
}

struct ChurchActivityFeed: View {
    let churchId: String?
    let churchName: String
    /// All church post IDs — used to scope likes/prayers/comments queries.
    let ownPostIds: [String]

    @State private var items: [ActivityItem] = []
    @State private var loading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            content
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task(id: churchSlugKey) { await load() }
    }

    private var churchSlugKey: String {
        // task(id:) uses this to refire when church identity changes
        "\(churchName)|\(ownPostIds.count)"
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text("Recent Activity")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.lcText)
            HStack(spacing: 4) {
                Circle().fill(Color.lcTeal).frame(width: 6, height: 6)
                Text("LIVE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(.lcTeal)
            }
            Spacer()
            Text("\(items.count) updates")
                .font(.system(size: 11))
                .foregroundColor(.lcText3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(Color.lcBorder),
            alignment: .bottom
        )
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if loading {
            ProgressView().tint(.lcNavy)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
        } else if items.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                        ActivityRow(item: item)
                        if idx < items.count - 1 {
                            Divider().background(Color.lcBorder.opacity(0.6)).padding(.leading, 60)
                        }
                    }
                }
            }
            .frame(maxHeight: 380)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🌱").font(.system(size: 28))
            Text("No engagement yet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.lcText)
            Text("Activity from followers — reactions, prayers, comments, and messages — will show up here as your community grows.")
                .font(.system(size: 12))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Load

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            items = try await fetchActivity()
        } catch {
            // Silent failure — keep prior items, log only
            print("[ChurchActivityFeed] load error: \(error.localizedDescription)")
        }
    }

    private func fetchActivity() async throws -> [ActivityItem] {
        let client = SupabaseService.shared.client
        guard !churchName.isEmpty else { return [] }

        let slug = ChurchSlug.make(churchName)
        let postIdParam = ownPostIds.isEmpty
            ? ["00000000-0000-0000-0000-000000000000"]
            : ownPostIds

        // Parallel fetches
        async let followsRows: [FollowRow] = client
            .from("follows")
            .select("id, follower_id, created_at")
            .eq("following_id", value: slug)
            .eq("following_type", value: "church")
            .order("created_at", ascending: false)
            .limit(15)
            .execute()
            .value

        async let likesRows: [LikeRow] = client
            .from("likes")
            .select("id, user_id, post_id, created_at")
            .in("post_id", values: postIdParam)
            .order("created_at", ascending: false)
            .limit(15)
            .execute()
            .value

        async let prayersRows: [PrayerRow] = client
            .from("prayer_responses")
            .select("id, user_id, prayer_post_id, created_at")
            .in("prayer_post_id", values: postIdParam)
            .order("created_at", ascending: false)
            .limit(15)
            .execute()
            .value

        async let commentsRows: [CommentRow] = client
            .from("comments")
            .select("id, author_id, post_id, content, created_at")
            .in("post_id", values: postIdParam)
            .order("created_at", ascending: false)
            .limit(15)
            .execute()
            .value

        async let inquiriesRows: [InquiryRow] = client
            .from("church_inquiries")
            .select("id, member_id, member_name, subject, type, created_at")
            .eq("church_name", value: churchName)
            .order("created_at", ascending: false)
            .limit(15)
            .execute()
            .value

        let follows = (try? await followsRows) ?? []
        let likes = (try? await likesRows) ?? []
        let prayers = (try? await prayersRows) ?? []
        let comments = (try? await commentsRows) ?? []
        let inquiries = (try? await inquiriesRows) ?? []

        // Resolve actor profiles in one batch
        var actorIds = Set<String>()
        for f in follows { actorIds.insert(f.follower_id) }
        for l in likes { actorIds.insert(l.user_id) }
        for p in prayers { actorIds.insert(p.user_id) }
        for c in comments { actorIds.insert(c.author_id) }
        for i in inquiries { if let mid = i.member_id { actorIds.insert(mid) } }

        var profileLookup: [String: ProfileRow] = [:]
        if !actorIds.isEmpty {
            let rows: [ProfileRow] = (try? await client
                .from("profiles")
                .select("id, full_name, photo_url")
                .in("id", values: Array(actorIds))
                .execute()
                .value) ?? []
            for r in rows { profileLookup[r.id] = r }
        }

        func actor(_ id: String?, fallback: String? = nil) -> (name: String, photo: String?) {
            guard let id, let p = profileLookup[id] else {
                return (fallback?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Someone", nil)
            }
            return (p.full_name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Someone", p.photo_url)
        }

        var out: [ActivityItem] = []

        for r in follows {
            let a = actor(r.follower_id)
            out.append(ActivityItem(
                id: "follow-\(r.id)",
                kind: .follow,
                actorId: r.follower_id,
                actorName: a.name,
                actorPhotoUrl: a.photo,
                message: "started following your church",
                target: nil,
                createdAt: r.created_at
            ))
        }

        for r in likes {
            let a = actor(r.user_id)
            out.append(ActivityItem(
                id: "like-\(r.id)",
                kind: .like,
                actorId: r.user_id,
                actorName: a.name,
                actorPhotoUrl: a.photo,
                message: "reacted to your post",
                target: nil,
                createdAt: r.created_at
            ))
        }

        for r in prayers {
            let a = actor(r.user_id)
            out.append(ActivityItem(
                id: "prayer-\(r.id)",
                kind: .prayer,
                actorId: r.user_id,
                actorName: a.name,
                actorPhotoUrl: a.photo,
                message: "prayed for your post",
                target: nil,
                createdAt: r.created_at
            ))
        }

        for r in comments {
            let a = actor(r.author_id)
            let preview = String((r.content ?? "").prefix(60))
            out.append(ActivityItem(
                id: "comment-\(r.id)",
                kind: .comment,
                actorId: r.author_id,
                actorName: a.name,
                actorPhotoUrl: a.photo,
                message: "commented on your post",
                target: preview.isEmpty ? nil : preview,
                createdAt: r.created_at
            ))
        }

        for r in inquiries {
            let a = actor(r.member_id, fallback: r.member_name)
            let verb: String
            switch r.type ?? "general" {
            case "prayer":     verb = "submitted a prayer request"
            case "visit":      verb = "asked about visiting"
            case "volunteer":  verb = "asked about volunteering"
            case "event":      verb = "asked about an event"
            default:           verb = "sent you a message"
            }
            out.append(ActivityItem(
                id: "inquiry-\(r.id)",
                kind: .inquiry,
                actorId: r.member_id,
                actorName: a.name,
                actorPhotoUrl: a.photo,
                message: verb,
                target: r.subject,
                createdAt: r.created_at
            ))
        }

        return out
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(12)
            .map { $0 }
    }
}

// MARK: - Row

private struct ActivityRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                (Text(item.actorName).bold().foregroundColor(.lcText)
                    + Text(" \(item.message)").foregroundColor(.lcText2))
                    .font(.system(size: 14))
                    .lineLimit(2)
                if let target = item.target, !target.isEmpty {
                    Text(target)
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            Text(relativeTime(item.createdAt))
                .font(.system(size: 11))
                .foregroundColor(.lcText3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let url = item.actorPhotoUrl, !url.isEmpty, let parsed = URL(string: url) {
                    AsyncImage(url: parsed) { phase in
                        if let img = phase.image { img.resizable().scaledToFill() }
                        else { initialFallback }
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    initialFallback
                }
            }
            .overlay(Circle().stroke(Color.lcBorder, lineWidth: 1))

            kindIcon
                .frame(width: 18, height: 18)
                .background(Circle().fill(kindTint))
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(x: 4, y: 4)
        }
    }

    private var initialFallback: some View {
        Circle()
            .fill(Color.lcNavy.opacity(0.10))
            .frame(width: 36, height: 36)
            .overlay(
                Text(String(item.actorName.first.map { String($0).uppercased() } ?? "?"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.lcNavy)
            )
    }

    private var kindIcon: some View {
        Text(kindEmoji)
            .font(.system(size: 9))
    }

    private var kindEmoji: String {
        switch item.kind {
        case .follow:  return "👥"
        case .like:    return "❤️"
        case .prayer:  return "🙏"
        case .comment: return "💬"
        case .inquiry: return "📬"
        case .rsvp:    return "🎟"
        }
    }

    private var kindTint: Color {
        switch item.kind {
        case .follow:  return Color.lcNavy.opacity(0.10)
        case .like:    return Color.red.opacity(0.10)
        case .prayer:  return Color.lcGoldLight
        case .comment: return Color.lcTeal.opacity(0.10)
        case .inquiry: return Color.lcCream
        case .rsvp:    return Color.purple.opacity(0.08)
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Decodable rows (private to this file)

private struct FollowRow: Decodable {
    let id: String
    let follower_id: String
    let created_at: Date
}
private struct LikeRow: Decodable {
    let id: String
    let user_id: String
    let post_id: String
    let created_at: Date
}
private struct PrayerRow: Decodable {
    let id: String
    let user_id: String
    let prayer_post_id: String
    let created_at: Date
}
private struct CommentRow: Decodable {
    let id: String
    let author_id: String
    let post_id: String
    let content: String?
    let created_at: Date
}
private struct InquiryRow: Decodable {
    let id: String
    let member_id: String?
    let member_name: String?
    let subject: String?
    let type: String?
    let created_at: Date
}
private struct ProfileRow: Decodable {
    let id: String
    let full_name: String?
    let photo_url: String?
}

// MARK: - Tiny helpers

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

/// Replicates the lcn-web `churchSlug()` helper so iOS and web compute the
/// same `following_id` value.
enum ChurchSlug {
    static func make(_ name: String?) -> String {
        let n = (name ?? "").lowercased()
        let allowed = CharacterSet.lowercaseLetters.union(.decimalDigits).union(CharacterSet(charactersIn: "-"))
        let mapped = n.unicodeScalars.map { allowed.contains($0) ? Character($0) : Character("-") }
        let str = String(mapped)
        // Collapse consecutive dashes + trim
        let collapsed = str.replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
        return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
