import SwiftUI

// MARK: - Navigation Route
//
// Typed destination for every possible notification tap.
// Hashable so it can be pushed onto a NavigationPath.

enum NotificationRoute: Hashable {
    case userProfile(UUID)
    case church(String, ChurchProfileTab)   // slug + initial tab
    /// Worshipper-side route to the Messages screen with an optional inquiry
    /// to auto-open. Triggered by `church_inquiry_reply` notification taps.
    case myInquiries(UUID?)
    case unavailable
}

// MARK: - Notifications View

struct NotificationsView: View {
    @EnvironmentObject var appState: AppState
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = true
    @State private var path = NavigationPath()

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if isLoading {
                    ScrollView { VStack(spacing: 0) { LCListSkeleton(rows: 6) } }
                } else if notifications.isEmpty {
                    LCEmptyState(
                        icon: "bell.slash",
                        title: "You're all caught up",
                        subtitle: "When churches you follow post, go live, or new people follow you, you'll see it here."
                    )
                } else {
                    notificationsList
                }
            }
            .navigationDestination(for: NotificationRoute.self) { route in
                routeDestination(route)
            }
            .background(Color.lcCream)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if unreadCount > 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Mark all read") {
                            Task { await markAllRead() }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.lcNavy)
                    }
                }
            }
        }
        .task { await loadNotifications() }
    }

    // MARK: - Route destination

    @ViewBuilder
    private func routeDestination(_ route: NotificationRoute) -> some View {
        switch route {
        case .userProfile(let userId):
            UserProfileView(userId: userId)

        case .church(let slug, let tab):
            if let submission = appState.church(bySlug: slug) {
                let church = appState.toChurch(submission)
                ChurchDetailView(church: church, initialTab: tab)
            } else {
                NotificationUnavailableView()
            }

        case .myInquiries(let inquiryId):
            if let userId = appState.currentUserId {
                MyInquiriesView(memberId: userId, focusInquiryId: inquiryId)
            } else {
                NotificationUnavailableView()
            }

        case .unavailable:
            NotificationUnavailableView()
        }
    }

    // MARK: - Route resolution
    //
    // Every notification type maps to a non-nil route.
    // Priority: structured fields → text inference → .unavailable.

    func route(for notification: AppNotification) -> NotificationRoute {
        switch notification.type {

        case "new_follower":
            // Prefer structured actor ID, then relatedId, then name match in title
            if let id = notification.actorUserId ?? notification.relatedId {
                return .userProfile(id)
            }
            if let user = MockDataProvider.allSeedUsers.first(where: {
                notification.title.localizedCaseInsensitiveContains($0.name)
            }) {
                return .userProfile(user.id)
            }

        case "church_live":
            if let slug = notification.churchSlug ?? inferredSlug(from: notification) {
                return .church(slug, .media)
            }

        case "new_event":
            if let slug = notification.churchSlug ?? inferredSlug(from: notification) {
                return .church(slug, .events)
            }

        case "new_post":
            if let slug = notification.churchSlug ?? inferredSlug(from: notification) {
                return .church(slug, .home)
            }
            if let actorId = notification.actorUserId {
                return .userProfile(actorId)
            }

        case "church_inquiry_reply":
            // related_id holds the inquiry UUID — pass it through so the
            // Messages screen can auto-open that conversation.
            return .myInquiries(notification.relatedId)

        default:
            // Best-effort: try user then church
            if let id = notification.actorUserId ?? notification.relatedId {
                return .userProfile(id)
            }
            if let slug = notification.churchSlug ?? inferredSlug(from: notification) {
                return .church(slug, .about)
            }
        }

        return .unavailable
    }

    /// Scans notification title + body for a known church name.
    /// Fallback for older Supabase rows that lack a churchSlug column.
    private func inferredSlug(from notification: AppNotification) -> String? {
        let text = [notification.title, notification.body ?? ""].joined(separator: " ")
        for church in appState.approvedChurches {
            if let name = church.churchName, text.localizedCaseInsensitiveContains(name) {
                return (name).lowercased().replacingOccurrences(of: " ", with: "-")
            }
        }
        return nil
    }

    // MARK: - Notifications list

    private var notificationsList: some View {
        List {
            ForEach(Array(notifications.enumerated()), id: \.element.id) { index, notification in
                // Plain Button — always reliable in a List inside a NavigationStack.
                // On tap: mark as read, then push the resolved route onto the path.
                Button {
                    Task { await markRead(notification) }
                    path.append(route(for: notification))
                } label: {
                    NotificationRowContent(notification: notification)
                }
                .buttonStyle(.plain)
                .listRowBackground(notification.isRead ? Color.white : Color.lcNavy.opacity(0.04))
                .listRowSeparatorTint(Color.lcBorder)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    if !notification.isRead {
                        Button {
                            withAnimation { markReadWithoutNavigation(notification) }
                            HapticEngine.impact(.light)
                        } label: {
                            Label("Mark Read", systemImage: "checkmark.circle")
                        }
                        .tint(.lcTeal)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.appStandard.delay(Double(index) * 0.04), value: notifications.count)
            }
        }
        .listStyle(.plain)
        .refreshable { await loadNotifications() }
    }

    private func markReadWithoutNavigation(_ notification: AppNotification) {
        Task { await markRead(notification) }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundColor(.lcText3)
            Text("No notifications yet")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lcText)
            Text("You'll see updates from churches and worshippers you follow.")
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Data actions

    private func loadNotifications() async {
        guard let userId = appState.currentUserId else { isLoading = false; return }
        do {
            let loaded = try await SupabaseService.shared.getNotifications(userId: userId)
            notifications = loaded
        } catch {
            // On failure, show real empty state — never fall back to mock
            // fixtures (those leak fake "Grace Community Church is LIVE"
            // entries into production builds).
            print("[NotificationsView] load failed: \(error.localizedDescription)")
            notifications = []
        }
        isLoading = false
    }

    private func markRead(_ notification: AppNotification) async {
        guard !notification.isRead else { return }
        do {
            try await SupabaseService.shared.markNotificationRead(notificationId: notification.id)
            if let idx = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[idx].isRead = true
            }
        } catch { print("Mark read error: \(error)") }
    }

    private func markAllRead() async {
        guard let userId = appState.currentUserId else { return }
        do {
            try await SupabaseService.shared.markAllNotificationsRead(userId: userId)
            for i in notifications.indices { notifications[i].isRead = true }
        } catch { print("Mark all read error: \(error)") }
    }
}

// MARK: - Notification Row Content (visual only — no navigation logic)

struct NotificationRowContent: View {
    let notification: AppNotification

    private var icon: String {
        switch notification.type {
        case "new_post":              return "doc.text.fill"
        case "new_follower":          return "person.fill.badge.plus"
        case "church_live":           return "antenna.radiowaves.left.and.right"
        case "new_event":             return "calendar.badge.plus"
        case "church_inquiry_reply":  return "bubble.left.and.bubble.right.fill"
        default:                      return "bell.fill"
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case "church_live":           return .red
        case "new_event":             return .lcNavy
        case "new_follower":          return .lcTeal
        case "new_post":              return .lcText2
        case "church_inquiry_reply":  return .lcTeal
        default:                      return .lcText3
        }
    }

    private var timeAgo: String {
        let diff = Date().timeIntervalSince(notification.createdAt)
        switch diff {
        case ..<3600:  return "\(Int(diff / 60))m ago"
        case ..<86400: return "\(Int(diff / 3600))h ago"
        default:       return "\(Int(diff / 86400))d ago"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(notification.title)
                    .font(.system(size: 14, weight: notification.isRead ? .regular : .semibold))
                    .foregroundColor(.lcText)
                    .fixedSize(horizontal: false, vertical: true)
                if let body = notification.body {
                    Text(body)
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                        .lineLimit(2)
                }
                Text(timeAgo)
                    .font(.system(size: 11))
                    .foregroundColor(.lcText3)
            }

            Spacer(minLength: 8)

            if !notification.isRead {
                Circle()
                    .fill(Color.lcNavy)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.lcText3.opacity(0.4))
                    .padding(.top, 4)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Unavailable fallback

struct NotificationUnavailableView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.lcText3)
            Text("Content Not Available")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.lcText)
            Text("This content may have been removed or is no longer available.")
                .font(.system(size: 14))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Go Back") { dismiss() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.lcNavy)
                .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.lcCream)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
