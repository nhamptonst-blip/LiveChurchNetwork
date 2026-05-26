import SwiftUI

// MARK: - Notification Preferences
//
// Per-category opt-out toggles. The DB-side trigger on `notifications`
// INSERT consults the matching row in `notification_preferences` and
// silently drops any insert the user has disabled — so flipping a switch
// here is the single source of truth for "stop sending me X."
//
// Mirrors the web tabs at:
//   - dashboard/edit/_components/worshipper-notifications-tab.tsx
//   - dashboard/edit/_components/church-notifications-tab.tsx

struct NotificationPreferencesView: View {
    @EnvironmentObject private var appState: AppState

    @State private var prefs = NotificationPreferences.defaults
    @State private var loading = true
    @State private var saving = false
    @State private var savedAt: Date?
    @State private var errorMessage: String?

    private var isChurchAdmin: Bool {
        appState.profile?.role == "church_admin"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if loading {
                    ForEach(0..<5, id: \.self) { _ in
                        LCSkeleton(height: 56, cornerRadius: 10)
                    }
                } else {
                    helperCopy

                    // Master switch — when off, suppresses every category.
                    PreferenceRow(
                        label: "All notifications",
                        description: "Master switch — turn this off to silence everything.",
                        emphasis: true,
                        isOn: bindingFor(\.pushEnabled),
                    )

                    Group {
                        if isChurchAdmin {
                            ForEach(churchOptions, id: \.label) { opt in
                                PreferenceRow(
                                    label: opt.label,
                                    description: opt.description,
                                    isOn: bindingFor(opt.keyPath),
                                )
                            }
                        } else {
                            ForEach(worshipperOptions, id: \.label) { opt in
                                PreferenceRow(
                                    label: opt.label,
                                    description: opt.description,
                                    isOn: bindingFor(opt.keyPath),
                                )
                            }
                        }
                    }
                    .opacity(prefs.pushEnabled ? 1 : 0.4)
                    .allowsHitTesting(prefs.pushEnabled)

                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if savedAt != nil {
                        Text(saving ? "Saving…" : "✓ Saved")
                            .font(.system(size: 12))
                            .foregroundColor(.lcText3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(16)
        }
        .background(Color.lcCream)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    // MARK: - Subviews

    private var helperCopy: some View {
        Text("Manage which notifications you receive. Changes save automatically.")
            .font(.system(size: 13))
            .foregroundColor(.lcText3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Binding helper
    //
    // Returns a Binding<Bool> for any prefs keypath that triggers an
    // optimistic save whenever the toggle flips. We don't surface an
    // explicit "Save" button — the trigger model means stale state on
    // network failure is the only recovery the user needs.

    private func bindingFor(_ keyPath: WritableKeyPath<NotificationPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { prefs[keyPath: keyPath] },
            set: { newValue in
                var next = prefs
                next[keyPath: keyPath] = newValue
                prefs = next
                Task { await persist(next) }
            },
        )
    }

    // MARK: - Data

    private func load() async {
        guard let uid = appState.currentUserId else {
            await MainActor.run { loading = false }
            return
        }
        do {
            let fresh = try await SupabaseService.shared.getNotificationPreferences(userId: uid)
            await MainActor.run {
                prefs = fresh
                loading = false
            }
        } catch {
            await MainActor.run {
                loading = false
                errorMessage = "Couldn't load preferences. Defaults applied — try again."
            }
        }
    }

    private func persist(_ next: NotificationPreferences) async {
        guard let uid = appState.currentUserId else { return }
        await MainActor.run { saving = true; errorMessage = nil }
        do {
            try await SupabaseService.shared.saveNotificationPreferences(userId: uid, prefs: next)
            await MainActor.run {
                saving = false
                savedAt = Date()
            }
        } catch {
            await MainActor.run {
                saving = false
                errorMessage = "Couldn't save. Please try again."
            }
        }
    }
}

// MARK: - Option config

private struct PrefOption {
    let label: String
    let description: String
    let keyPath: WritableKeyPath<NotificationPreferences, Bool>
}

private let worshipperOptions: [PrefOption] = [
    .init(label: "New Followers",         description: "When someone follows you",                                  keyPath: \.newFollowers),
    .init(label: "Likes",                 description: "When people like your posts",                               keyPath: \.newLikes),
    .init(label: "Comments",              description: "When people comment on your posts",                         keyPath: \.newComments),
    .init(label: "Prayer Responses",      description: "When someone prays for your prayer post",                   keyPath: \.prayerResponses),
    .init(label: "Church Updates",        description: "New posts and events from churches you follow",             keyPath: \.churchUpdates),
    .init(label: "Live Services",         description: "When churches you follow go live",                          keyPath: \.churchLive),
    .init(label: "Replies to my messages",description: "When a church admin replies to your inquiry",               keyPath: \.inquiryReplies),
]

private let churchOptions: [PrefOption] = [
    .init(label: "New Member Inquiries",  description: "When someone messages your church",                         keyPath: \.newInquiries),
    .init(label: "New Followers",         description: "When someone follows your church",                          keyPath: \.newFollowers),
    .init(label: "Comments",              description: "When people comment on your posts",                         keyPath: \.newComments),
    .init(label: "Likes",                 description: "When people like your posts",                               keyPath: \.newLikes),
    .init(label: "Prayer Responses",      description: "When someone prays for one of your prayer posts",           keyPath: \.prayerResponses),
]

// MARK: - Row

private struct PreferenceRow: View {
    let label: String
    let description: String
    var emphasis: Bool = false
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lcText)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.lcText3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.lcNavy)
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(emphasis ? Color.lcNavy.opacity(0.3) : Color.lcBorder, lineWidth: 1)
        )
        .background(emphasis ? Color.lcNavy.opacity(0.04) : Color.clear)
        .cornerRadius(10)
    }
}
