import SwiftUI

// MARK: - Safety Menus
//
// Trust-and-safety primitives shared across post cards, profile headers,
// and comment rows. Mirrors the web pattern in lcn-web/src/components/
// post-action-menu.tsx + profile-action-menu.tsx so both platforms feel
// identical: Report (with reason picker) + Block + Hide.

// MARK: - Post action menu

struct PostActionMenuView: View {
    let post: Post
    /// Current viewer. When nil, only Report shows.
    let viewerId: UUID?
    /// Called after a hide or block so the parent can splice the post out.
    var onDismiss: (() -> Void)? = nil

    @EnvironmentObject private var appState: AppState
    @State private var showingReport = false
    @State private var showingBlockConfirm = false

    private var isOwn: Bool { viewerId != nil && viewerId == post.authorId }
    private var canBlock: Bool { viewerId != nil && !isOwn }

    var body: some View {
        Menu {
            Button {
                showingReport = true
            } label: {
                Label("Report Post", systemImage: "flag")
            }
            if viewerId != nil {
                Button {
                    Task { await hide() }
                } label: {
                    Label("Hide This Post", systemImage: "eye.slash")
                }
            }
            if canBlock {
                Divider()
                Button(role: .destructive) {
                    showingBlockConfirm = true
                } label: {
                    Label("Block \(post.authorName)", systemImage: "hand.raised")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.lcText3)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .sheet(isPresented: $showingReport) {
            ReportSheet(
                contentType: .post,
                contentId: post.id,
                targetLabel: "\(post.authorName)'s post",
                viewerId: viewerId
            )
        }
        .sheet(isPresented: $showingBlockConfirm) {
            BlockConfirmSheet(
                targetName: post.authorName,
                kind: .person,
                onConfirm: { reason in
                    await block(reason: reason)
                    onDismiss?()
                }
            )
        }
    }

    private func hide() async {
        guard let viewerId else { return }
        do {
            try await SupabaseService.shared.hidePost(userId: viewerId, postId: post.id)
            await appState.refreshSafetyFilters()
            await MainActor.run { onDismiss?() }
        } catch {
            print("[hide] failed: \(error.localizedDescription)")
        }
    }

    private func block(reason: String?) async {
        guard let viewerId else { return }
        do {
            try await SupabaseService.shared.blockUser(
                blockerId: viewerId,
                blockedId: post.authorId,
                reason: reason
            )
            await appState.refreshSafetyFilters()
        } catch {
            print("[block] failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Profile action menu

struct ProfileActionMenuView: View {
    let targetUserId: UUID
    let targetName: String
    let kind: ProfileKind
    let viewerId: UUID?
    var onBlocked: (() -> Void)? = nil

    enum ProfileKind { case person, church }

    @EnvironmentObject private var appState: AppState
    @State private var showingReport = false
    @State private var showingBlockConfirm = false

    private var isOwn: Bool { viewerId == targetUserId }

    var body: some View {
        // Hidden entirely on own profile.
        if isOwn {
            EmptyView()
        } else {
            Menu {
                Button {
                    showingReport = true
                } label: {
                    Label("Report \(kind == .church ? "Church" : "Profile")",
                          systemImage: "flag")
                }
                if viewerId != nil {
                    Divider()
                    Button(role: .destructive) {
                        showingBlockConfirm = true
                    } label: {
                        Label("Block \(targetName)", systemImage: "hand.raised")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lcText3)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.001)))
            }
            .sheet(isPresented: $showingReport) {
                ReportSheet(
                    contentType: kind == .church ? .church : .profile,
                    contentId: targetUserId,
                    targetLabel: targetName,
                    viewerId: viewerId
                )
            }
            .sheet(isPresented: $showingBlockConfirm) {
                BlockConfirmSheet(
                    targetName: targetName,
                    kind: kind == .church ? .church : .person,
                    onConfirm: { reason in
                        await block(reason: reason)
                        onBlocked?()
                    }
                )
            }
        }
    }

    private func block(reason: String?) async {
        guard let viewerId else { return }
        do {
            try await SupabaseService.shared.blockUser(
                blockerId: viewerId,
                blockedId: targetUserId,
                reason: reason
            )
            await appState.refreshSafetyFilters()
        } catch {
            print("[block] failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Report sheet

struct ReportSheet: View {
    let contentType: FlagContentType
    let contentId: UUID
    let targetLabel: String
    let viewerId: UUID?

    @Environment(\.dismiss) private var dismiss
    @State private var reason: FlagReason? = nil
    @State private var notes: String = ""
    @State private var submitting = false
    @State private var done = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.lcCream.ignoresSafeArea()

                if done {
                    VStack(spacing: 12) {
                        Spacer()
                        ZStack {
                            Circle().fill(Color.green.opacity(0.15))
                                .frame(width: 60, height: 60)
                            Image(systemName: "checkmark")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.green)
                        }
                        Text("Report received")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lcText)
                        Text("Thank you — we'll review this shortly.")
                            .font(.system(size: 13))
                            .foregroundColor(.lcText3)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reports go to our moderation team. Reporters are not shown to the person being reported.")
                                .font(.system(size: 12))
                                .foregroundColor(.lcText3)

                            Text("WHY ARE YOU REPORTING THIS?")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.lcText3)
                                .tracking(0.5)

                            VStack(spacing: 8) {
                                ForEach(FlagReason.allCases, id: \.self) { opt in
                                    Button {
                                        reason = opt
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(opt.label)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.lcText)
                                            Text(opt.helper)
                                                .font(.system(size: 12))
                                                .foregroundColor(.lcText3)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(reason == opt ? Color.lcNavy.opacity(0.05) : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(reason == opt ? Color.lcNavy : Color.lcBorder,
                                                        lineWidth: reason == opt ? 1.5 : 1)
                                        )
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("NOTES (OPTIONAL)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.lcText3)
                                    .tracking(0.5)
                                TextEditor(text: $notes)
                                    .font(.system(size: 14))
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.lcBorder, lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                            }

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Report \(targetLabel)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(submitting)
                }
                if !done {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task { await submit() }
                        } label: {
                            if submitting {
                                ProgressView().tint(.lcNavy)
                            } else {
                                Text("Submit")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(reason == nil ? .lcText3 : .lcNavy)
                            }
                        }
                        .disabled(reason == nil || submitting)
                    }
                }
            }
        }
    }

    private func submit() async {
        guard let reason else { return }
        submitting = true
        errorMessage = nil
        do {
            try await SupabaseService.shared.reportContent(
                reporterId: viewerId,
                contentType: contentType,
                contentId: contentId,
                reason: reason,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            done = true
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        } catch {
            errorMessage = "Couldn't send the report. Please try again."
        }
        submitting = false
    }
}

// MARK: - Block confirm sheet

struct BlockConfirmSheet: View {
    let targetName: String
    let kind: BlockKind
    let onConfirm: (String?) async -> Void

    enum BlockKind { case person, church }

    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var busy = false

    private var noun: String {
        kind == .church ? "this church" : targetName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.lcCream.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Block \(noun)?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.lcText)

                        VStack(alignment: .leading, spacing: 8) {
                            BulletRow("You won't see their \(kind == .church ? "posts, events, or live streams" : "posts or comments") anywhere on the app.")
                            BulletRow("They won't be able to follow you or send you messages.")
                            BulletRow("They won't be told they've been blocked.")
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("NOTE TO YOURSELF (OPTIONAL)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.lcText3)
                                .tracking(0.5)
                            TextField("Why you're blocking, for future reference.",
                                      text: $reason)
                                .font(.system(size: 14))
                                .padding(10)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.lcBorder, lineWidth: 1)
                                )
                                .cornerRadius(12)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.disabled(busy)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            busy = true
                            let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
                            await onConfirm(trimmed.isEmpty ? nil : trimmed)
                            busy = false
                            dismiss()
                        }
                    } label: {
                        if busy {
                            ProgressView().tint(.red)
                        } else {
                            Text("Block")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(busy)
                }
            }
        }
    }
}

private struct BulletRow: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 14))
                .foregroundColor(.lcText3)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.lcText2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
