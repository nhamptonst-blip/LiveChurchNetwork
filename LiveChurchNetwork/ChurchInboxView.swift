import SwiftUI

// MARK: - Church Inbox View
//
// Church-admin view of incoming member inquiries.
// Accessed from ChurchAdminDashboardView.
// Supports filter by status and type, mark-replied, and archive.

struct ChurchInboxView: View {
    let churchName: String

    @State private var inquiries: [ChurchInquiry] = []
    @State private var isLoading = true
    @State private var filterType: InquiryType? = nil       // nil = all types
    @State private var filterStatus: InquiryStatus? = .new  // default: show new
    @State private var selectedInquiry: ChurchInquiry? = nil
    @State private var errorMessage: String?
    /// Polls every 15s while the inbox is on screen so new inquiries from
    /// members appear without a manual refresh. APNs handles bell-badge
    /// notifications outside the app.
    @State private var refreshTask: Task<Void, Never>?

    // MARK: - Derived

    private var filtered: [ChurchInquiry] {
        inquiries.filter { inquiry in
            let typeOK   = filterType   == nil || inquiry.type   == filterType!.rawValue
            let statusOK = filterStatus == nil || inquiry.status == filterStatus!.rawValue
            return typeOK && statusOK
        }
    }

    private var newCount: Int {
        inquiries.filter { $0.status == InquiryStatus.new.rawValue }.count
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            statusFilterBar
            Divider()
            typeFilterBar

            if isLoading {
                ScrollView { VStack(spacing: 0) { LCListSkeleton(rows: 5) } }
            } else if let err = errorMessage {
                LCErrorState(
                    title: "Inbox unavailable",
                    message: err,
                    onRetry: { Task { await load() } }
                )
            } else if filtered.isEmpty {
                LCEmptyState(
                    icon: filterStatus == .new ? "tray" : filterStatus == .archived ? "archivebox" : "tray.full",
                    title: filterStatus == .new ? "No new inquiries" : "Nothing here",
                    subtitle: filterStatus == .new
                        ? "When members reach out, their messages will appear here. Make sure your profile is complete so people can find you."
                        : "No inquiries match this filter."
                )
            } else {
                inquiryList
            }
        }
        .background(Color.lcCream)
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedInquiry) { inquiry in
            InquiryDetailView(
                inquiry: inquiry,
                onStatusChange: { updated in
                    if let idx = inquiries.firstIndex(where: { $0.id == updated.id }) {
                        inquiries[idx] = updated
                    }
                },
                onDelete: { id in
                    inquiries.removeAll { $0.id == id }
                    selectedInquiry = nil
                }
            )
        }
        .task { await load() }
        .onAppear { startAutoRefresh() }
        .onDisappear { refreshTask?.cancel(); refreshTask = nil }
    }

    private func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000) // 15s
                if Task.isCancelled { return }
                await silentRefresh()
            }
        }
    }

    /// Refresh without toggling the spinner so the screen doesn't flicker.
    private func silentRefresh() async {
        do {
            let fresh = try await SupabaseService.shared.getInquiries(churchName: churchName)
            await MainActor.run {
                inquiries = fresh
                if let current = selectedInquiry,
                   let updated = fresh.first(where: { $0.id == current.id }) {
                    selectedInquiry = updated
                }
            }
        } catch {
            print("[ChurchInbox] silent refresh failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Filter bars

    private var statusFilterBar: some View {
        // Show counts on every pill so the church admin can see how many
        // past messages live behind Replied / Archived / All — without that,
        // a marked-replied inquiry can feel "lost."
        HStack(spacing: 0) {
            statusPill(label: pillLabel("New",      count: newCount),       status: .new)
            statusPill(label: pillLabel("Replied",  count: repliedCount),   status: .replied)
            statusPill(label: pillLabel("Archived", count: archivedCount),  status: .archived)
            statusPill(label: pillLabel("All",      count: inquiries.count), status: nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
    }

    private func pillLabel(_ name: String, count: Int) -> String {
        count > 0 ? "\(name) (\(count))" : name
    }

    private var repliedCount: Int {
        inquiries.filter { $0.status == InquiryStatus.replied.rawValue }.count
    }
    private var archivedCount: Int {
        inquiries.filter { $0.status == InquiryStatus.archived.rawValue }.count
    }

    private func statusPill(label: String, status: InquiryStatus?) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.14)) { filterStatus = status }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: filterStatus == status ? .bold : .regular))
                .foregroundColor(filterStatus == status ? .white : .lcText3)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(filterStatus == status ? Color.lcNavy : Color.clear)
                .cornerRadius(20)
        }
        .frame(maxWidth: .infinity)
    }

    private var typeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                typeChip(label: "All", type: nil)
                ForEach(InquiryType.allCases, id: \.self) { type in
                    typeChip(label: type.label, type: type)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.white)
    }

    private func typeChip(label: String, type: InquiryType?) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.14)) { filterType = type }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: filterType == type ? .semibold : .regular))
                .foregroundColor(filterType == type ? .lcNavy : .lcText3)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(filterType == type
                            ? Color.lcNavy.opacity(0.10)
                            : Color.lcBorder.opacity(0.4))
                .cornerRadius(20)
        }
    }

    // MARK: - Inquiry list

    private var inquiryList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filtered) { inquiry in
                    Button { selectedInquiry = inquiry } label: {
                        InquiryRowView(inquiry: inquiry)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 72)
                }
            }
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            .padding(16)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Empty / error

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 38))
                .foregroundColor(.lcText3)
                .padding(.top, 40)
            Text(filterStatus == .new ? "No new inquiries" : "Nothing here")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.lcText)
            Text("Inquiries from members will appear here.")
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
            Spacer()
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundColor(.lcText3)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Load

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            inquiries = try await SupabaseService.shared.getInquiries(churchName: churchName)
        } catch {
            errorMessage = "Couldn't load inquiries. Please try again."
        }
        isLoading = false
    }
}

// MARK: - Inquiry Row

private struct InquiryRowView: View {
    let inquiry: ChurchInquiry

    var body: some View {
        HStack(spacing: 14) {
            // Type icon
            ZStack {
                Circle()
                    .fill(iconBg)
                    .frame(width: 40, height: 40)
                Image(systemName: inquiry.inquiryType.icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconFg)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(inquiry.memberName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lcText)
                        .lineLimit(1)
                    if inquiry.inquiryStatus == .new {
                        Circle()
                            .fill(Color.lcNavy)
                            .frame(width: 6, height: 6)
                    }
                    Spacer()
                    Text(timeAgo(inquiry.createdAt))
                        .font(.system(size: 11))
                        .foregroundColor(.lcText3)
                }
                Text(inquiry.subject)
                    .font(.system(size: 13, weight: inquiry.inquiryStatus == .new ? .medium : .regular))
                    .foregroundColor(.lcText2)
                    .lineLimit(1)
                Text(inquiry.inquiryType.fullLabel)
                    .font(.system(size: 11))
                    .foregroundColor(.lcText3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var iconBg: Color {
        switch inquiry.inquiryType {
        case .prayer:    return Color.lcTeal.opacity(0.12)
        case .visit:     return Color.lcGold.opacity(0.12)
        case .volunteer: return Color.red.opacity(0.10)
        case .event:     return Color.purple.opacity(0.10)
        default:         return Color.lcNavy.opacity(0.08)
        }
    }

    private var iconFg: Color {
        switch inquiry.inquiryType {
        case .prayer:    return .lcTeal
        case .visit:     return .lcGold
        case .volunteer: return .red
        case .event:     return .purple
        default:         return .lcNavy
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        switch diff {
        case ..<3600:   return "\(Int(diff/60))m"
        case ..<86400:  return "\(Int(diff/3600))h"
        default:        return "\(Int(diff/86400))d"
        }
    }
}

// MARK: - Inquiry Detail Sheet

struct InquiryDetailView: View {
    let inquiry: ChurchInquiry
    let onStatusChange: (ChurchInquiry) -> Void
    /// Called when the church admin permanently deletes the inquiry — the
    /// parent removes it from the local list and dismisses the sheet.
    let onDelete: ((UUID) -> Void)?

    init(
        inquiry: ChurchInquiry,
        onStatusChange: @escaping (ChurchInquiry) -> Void,
        onDelete: ((UUID) -> Void)? = nil
    ) {
        self.inquiry = inquiry
        self.onStatusChange = onStatusChange
        self.onDelete = onDelete
    }

    @Environment(\.dismiss) private var dismiss
    @State private var isUpdating = false
    @State private var showDeleteConfirm = false
    @State private var actionError: String?
    /// Controls the in-app reply composer sheet.
    @State private var showReplyComposer = false
    /// Local mirror of the saved reply so the detail view updates instantly
    /// after the church admin submits a reply (without waiting for a refetch).
    @State private var savedReplyText: String?
    @State private var savedReplyAt: Date?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Type + member header
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.lcNavy.opacity(0.08))
                                .frame(width: 48, height: 48)
                            Image(systemName: inquiry.inquiryType.icon)
                                .font(.system(size: 20))
                                .foregroundColor(.lcNavy)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(inquiry.memberName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.lcText)
                            Text(inquiry.inquiryType.fullLabel)
                                .font(.system(size: 12))
                                .foregroundColor(.lcText3)
                        }
                        Spacer()
                        statusBadge
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(14)

                    // Subject + body
                    VStack(alignment: .leading, spacing: 12) {
                        Text(inquiry.subject)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.lcText)

                        Text(inquiry.body)
                            .font(.system(size: 15))
                            .foregroundColor(.lcText2)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(14)

                    // Existing reply (if the admin has already replied) —
                    // shown read-only above the action buttons so they can see
                    // what they sent and when, and re-open the composer to edit.
                    if let body = currentReplyText, !body.isEmpty {
                        replyPanel(body: body, sentAt: currentReplyAt)
                    }

                    // Actions
                    VStack(spacing: 10) {
                        // Write a reply inside the app. The composer is a sheet
                        // with a TextEditor; submitting writes reply_text /
                        // replied_at and flips status to 'replied'.
                        actionButton(
                            label: currentReplyText?.isEmpty == false ? "Edit Reply" : "Write Reply",
                            icon: "bubble.left.and.bubble.right.fill",
                            color: .lcNavy
                        ) { showReplyComposer = true }

                        if inquiry.inquiryStatus == .new && (currentReplyText ?? "").isEmpty {
                            actionButton(
                                label: "Mark as Replied",
                                icon: "checkmark.circle",
                                color: .lcTeal
                            ) { await updateStatus(.replied) }
                        }

                        if inquiry.inquiryStatus != .archived {
                            actionButton(
                                label: "Archive",
                                icon: "archivebox",
                                color: .lcText3
                            ) { await updateStatus(.archived) }
                        }

                        // Permanent delete — confirmation alert below.
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash").font(.system(size: 14))
                                Text("Delete").font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(12)
                        }
                        .disabled(isUpdating)
                    }

                    if let err = actionError {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(Color.lcCream)
            .navigationTitle("Inquiry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.lcNavy)
                }
            }
            .alert("Delete this inquiry?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { Task { await deleteInquiry() } }
            } message: {
                Text("This permanently removes the message. The member won't be notified.")
            }
            .sheet(isPresented: $showReplyComposer) {
                ReplyComposerSheet(
                    inquiry: inquiry,
                    initialText: currentReplyText ?? "",
                    onSubmit: { text in await submitReply(text) }
                )
            }
        }
    }

    // MARK: - Saved-reply accessors
    //
    // Prefer the locally-mirrored value (set on submit) over the inquiry passed
    // in by the parent — the parent only refreshes from Supabase between sheets.

    private var currentReplyText: String? {
        savedReplyText ?? inquiry.replyText
    }

    private var currentReplyAt: Date? {
        savedReplyAt ?? inquiry.repliedAt
    }

    // MARK: - Reply panel

    @ViewBuilder
    private func replyPanel(body: String, sentAt: Date?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.bubble.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.lcTeal)
                Text("Your reply")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lcText)
                Spacer()
                if let sentAt {
                    Text(sentAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundColor(.lcText3)
                }
            }
            Text(body)
                .font(.system(size: 14))
                .foregroundColor(.lcText2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lcTeal.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.lcTeal.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    // MARK: - In-app reply

    /// Persists the church admin's reply to Supabase, mirrors it locally, and
    /// notifies the parent so the inbox row updates without a full refetch.
    private func submitReply(_ text: String) async {
        actionError = nil
        isUpdating = true
        defer { isUpdating = false }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try await SupabaseService.shared.replyToInquiry(inquiry: inquiry, text: trimmed)
            ReviewPromptService.recordTrigger(.repliedToInquiry)
            let now = Date()
            savedReplyText = trimmed
            savedReplyAt = now
            var updated = inquiry
            updated.status = InquiryStatus.replied.rawValue
            updated.replyText = trimmed
            updated.repliedAt = now
            onStatusChange(updated)
            showReplyComposer = false
        } catch {
            actionError = "Couldn't send the reply. Please try again."
        }
    }

    // MARK: - Delete

    private func deleteInquiry() async {
        isUpdating = true
        do {
            try await SupabaseService.shared.deleteInquiry(id: inquiry.id)
            onDelete?(inquiry.id)
            dismiss()
        } catch {
            actionError = "Couldn't delete the inquiry. Try again."
        }
        isUpdating = false
    }

    private var statusBadge: some View {
        let (label, color) = statusStyle(inquiry.inquiryStatus)
        return Text(label)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(20)
    }

    private func statusStyle(_ status: InquiryStatus) -> (String, Color) {
        switch status {
        case .new:      return ("New",      .lcNavy)
        case .replied:  return ("Replied",  .lcTeal)
        case .archived: return ("Archived", .lcText3)
        }
    }

    private func actionButton(
        label: String, icon: String, color: Color,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 8) {
                if isUpdating {
                    ProgressView().tint(color)
                } else {
                    Image(systemName: icon).font(.system(size: 14))
                    Text(label).font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(color.opacity(0.08))
            .cornerRadius(12)
        }
        .disabled(isUpdating)
    }

    private func updateStatus(_ status: InquiryStatus) async {
        isUpdating = true
        do {
            try await SupabaseService.shared.updateInquiryStatus(id: inquiry.id, status: status)
            var updated = inquiry
            updated.status = status.rawValue
            onStatusChange(updated)
        } catch {
            // Status update failure is non-critical; dismiss anyway
        }
        isUpdating = false
    }
}

// MARK: - Reply Composer Sheet
//
// In-app reply composer. The church admin types directly into a TextEditor;
// Send persists via `replyToInquiry` and dismisses. Available on every
// inquiry — composing a fresh reply, or editing an existing one (initialText
// is seeded from the saved reply when present).

private struct ReplyComposerSheet: View {
    let inquiry: ChurchInquiry
    let initialText: String
    let onSubmit: (String) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var isSending = false
    @FocusState private var editorFocused: Bool

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {

                // Original-message context — keeps the church grounded in
                // what they're replying to without making them scroll away.
                VStack(alignment: .leading, spacing: 6) {
                    Text("Replying to \(inquiry.memberName)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.lcText3)
                    Text(inquiry.subject)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.lcText)
                    Text(inquiry.body)
                        .font(.system(size: 13))
                        .foregroundColor(.lcText2)
                        .lineLimit(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.lcCream)
                .cornerRadius(10)

                // Composer
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .focused($editorFocused)
                        .font(.system(size: 15))
                        .foregroundColor(.lcText)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 200)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.lcBorder, lineWidth: 1)
                        )
                        .cornerRadius(12)
                    if text.isEmpty {
                        Text("Write your reply…")
                            .font(.system(size: 15))
                            .foregroundColor(.lcText3)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(Color.lcCream)
            .navigationTitle("Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.lcText2)
                        .disabled(isSending)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            isSending = true
                            await onSubmit(trimmed)
                            isSending = false
                        }
                    } label: {
                        if isSending {
                            ProgressView().tint(.lcNavy)
                        } else {
                            Text("Send")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(trimmed.isEmpty ? .lcText3 : .lcNavy)
                        }
                    }
                    .disabled(trimmed.isEmpty || isSending)
                }
            }
            .onAppear {
                if text.isEmpty { text = initialText }
                editorFocused = true
            }
        }
    }
}
