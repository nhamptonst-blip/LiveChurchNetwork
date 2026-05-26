import SwiftUI

// MARK: - Blocked Accounts management
//
// Worshipper or church admin can review every account they've blocked and
// unblock with one tap. Mirrors the web BlockedAccountsList component so
// behavior is identical across platforms.

struct BlockedAccountsView: View {
    @EnvironmentObject private var appState: AppState

    @State private var entries: [BlockedEntry]? = nil
    @State private var busyId: UUID? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        Group {
            if let entries {
                if entries.isEmpty {
                    LCEmptyState(
                        icon: "hand.raised",
                        title: "No blocked accounts",
                        subtitle: "When you block someone, they'll appear here. You can unblock anytime."
                    )
                } else {
                    list(entries)
                }
            } else if let err = errorMessage {
                LCErrorState(
                    title: "Couldn't load blocked accounts",
                    message: err,
                    onRetry: { Task { await load() } }
                )
            } else {
                ScrollView { LCListSkeleton(rows: 4) }
            }
        }
        .background(Color.lcCream)
        .navigationTitle("Blocked Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    // MARK: - List

    @ViewBuilder
    private func list(_ entries: [BlockedEntry]) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(entries) { entry in
                    row(entry)
                    if entry.id != entries.last?.id {
                        Divider().padding(.leading, 70)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.lcBorder, lineWidth: 1)
            )
            .padding(16)

            Text("Blocked accounts can't see your activity, and you don't see theirs. Tap Unblock to restore.")
                .font(.system(size: 12))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func row(_ entry: BlockedEntry) -> some View {
        HStack(spacing: 14) {
            avatar(entry)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lcText)
                    .lineLimit(1)
                Text(metadata(for: entry))
                    .font(.system(size: 11))
                    .foregroundColor(.lcText3)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Button {
                Task { await unblock(entry.blockedId) }
            } label: {
                if busyId == entry.blockedId {
                    ProgressView().tint(.lcNavy)
                        .frame(width: 70, height: 32)
                } else {
                    Text("Unblock")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.lcText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.lcBorder, lineWidth: 1)
                        )
                }
            }
            .buttonStyle(.plain)
            .disabled(busyId != nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func avatar(_ entry: BlockedEntry) -> some View {
        if let url = entry.photoUrl, !url.isEmpty, let parsed = URL(string: url) {
            AsyncImage(url: parsed) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    initialsAvatar(entry.name)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(entry.kind == .church
                ? AnyShape(RoundedRectangle(cornerRadius: 8))
                : AnyShape(Circle())
            )
        } else {
            initialsAvatar(entry.name)
                .clipShape(entry.kind == .church
                    ? AnyShape(RoundedRectangle(cornerRadius: 8))
                    : AnyShape(Circle())
                )
        }
    }

    private func initialsAvatar(_ name: String) -> some View {
        ZStack {
            Color.lcNavy.opacity(0.10)
                .frame(width: 40, height: 40)
            Text(name.prefix(1).uppercased())
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.lcNavy)
        }
    }

    private func metadata(for entry: BlockedEntry) -> String {
        let kindLabel = entry.kind == .church ? "Church" : "Person"
        let when = relative(entry.blockedAt)
        var parts = ["\(kindLabel) · blocked \(when)"]
        if let reason = entry.reason, !reason.isEmpty {
            parts.append(reason)
        }
        return parts.joined(separator: " · ")
    }

    private func relative(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        switch diff {
        case ..<60:    return "just now"
        case ..<3600:  return "\(Int(diff/60))m ago"
        case ..<86400: return "\(Int(diff/3600))h ago"
        default:       return "\(Int(diff/86400))d ago"
        }
    }

    // MARK: - Actions

    private func load() async {
        guard let uid = appState.currentUserId else {
            entries = []
            return
        }
        errorMessage = nil
        do {
            let fresh = try await SupabaseService.shared.getBlockedAccounts(userId: uid)
            await MainActor.run { entries = fresh }
        } catch {
            await MainActor.run {
                entries = nil
                errorMessage = "Please try again in a moment."
            }
        }
    }

    private func unblock(_ blockedId: UUID) async {
        guard let uid = appState.currentUserId else { return }
        await MainActor.run { busyId = blockedId }
        do {
            try await SupabaseService.shared.unblockUser(blockerId: uid, blockedId: blockedId)
            await appState.refreshSafetyFilters()
            await MainActor.run {
                entries = entries?.filter { $0.blockedId != blockedId }
                busyId = nil
            }
        } catch {
            await MainActor.run {
                busyId = nil
                errorMessage = "Couldn't unblock. Please try again."
            }
        }
    }
}

/// Type-erased Shape so we can pick `Circle` vs `RoundedRectangle` for
/// person-vs-church avatars in a single `.clipShape` call.
private struct AnyShape: Shape {
    private let path: (CGRect) -> Path
    init<S: Shape>(_ shape: S) {
        self.path = { rect in shape.path(in: rect) }
    }
    func path(in rect: CGRect) -> Path { path(rect) }
}
