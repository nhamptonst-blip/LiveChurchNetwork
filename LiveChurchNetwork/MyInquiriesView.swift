import SwiftUI

// MARK: - My Inquiries (Messages) View
//
// Worshipper-side view of inquiries they've submitted to churches.
// Mirrors the church admin's Inbox but inverts the perspective: the member
// sees what they sent, the church's reply (if any), and the status.
//
// Presented as a sheet from WorkshipperDashboardView. Notification taps with
// `type == "church_inquiry_reply"` route here too — when `focusInquiryId`
// is supplied, that row auto-opens on appear.

struct MyInquiriesView: View {
    let memberId: UUID
    /// Optional inquiry to auto-open when the view appears (set when the user
    /// arrived via a "church replied" notification).
    let focusInquiryId: UUID?

    @State private var inquiries: [ChurchInquiry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selected: ChurchInquiry?
    /// Drives the auto-refresh loop. While the view is visible we poll
    /// every 15s so a reply written on web (or by another church admin)
    /// shows up without the user having to leave and return. The bell
    /// badge for the same event arrives via APNs separately.
    @State private var refreshTask: Task<Void, Never>?

    init(memberId: UUID, focusInquiryId: UUID? = nil) {
        self.memberId = memberId
        self.focusInquiryId = focusInquiryId
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ScrollView {
                        VStack(spacing: 0) { LCListSkeleton(rows: 4) }
                    }
                } else if let err = errorMessage {
                    LCErrorState(
                        title: "Couldn't load messages",
                        message: err,
                        onRetry: { Task { await load() } }
                    )
                } else if inquiries.isEmpty {
                    LCEmptyState(
                        icon: "bubble.left.and.bubble.right",
                        title: "No messages yet",
                        subtitle: "When you reach out to a church, your conversations will live here."
                    )
                } else {
                    list
                }
            }
            .background(Color.lcCream)
            .navigationTitle("My Messages")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $selected) { inquiry in
            MemberInquiryDetailView(inquiry: inquiry)
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

    /// Like `load()` but doesn't toggle the spinner — used by the timer so
    /// the user doesn't see the screen flicker.
    private func silentRefresh() async {
        do {
            let fresh = try await SupabaseService.shared.getInquiriesForMember(memberId: memberId)
            await MainActor.run {
                inquiries = fresh
                // If the open detail sheet matches a refreshed row, update
                // its bound copy in place so the reply renders live.
                if let current = selected,
                   let updated = fresh.first(where: { $0.id == current.id }) {
                    selected = updated
                }
            }
        } catch {
            // Silent — we don't want a transient network blip to wipe the UI.
            print("[MyInquiries] silent refresh failed: \(error.localizedDescription)")
        }
    }

    // MARK: - List

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(inquiries) { inquiry in
                    Button { selected = inquiry } label: {
                        MyInquiryRow(inquiry: inquiry)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 64)
                }
            }
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            .padding(16)
            .padding(.bottom, 24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 38))
                .foregroundColor(.lcText3)
            Text("No messages yet")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.lcText)
            Text("When you reach out to a church, your conversations will live here.")
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
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
            inquiries = try await SupabaseService.shared.getInquiriesForMember(memberId: memberId)
            // Auto-open the requested inquiry once the list resolves so a
            // notification tap lands directly on the church's reply.
            if let target = focusInquiryId,
               let match = inquiries.first(where: { $0.id == target }) {
                selected = match
            }
        } catch {
            errorMessage = "Couldn't load your messages. Please try again."
        }
        isLoading = false
    }
}

// MARK: - Row

private struct MyInquiryRow: View {
    let inquiry: ChurchInquiry

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.lcNavy.opacity(0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: inquiry.inquiryType.icon)
                    .font(.system(size: 15))
                    .foregroundColor(.lcNavy)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(inquiry.churchName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lcText)
                        .lineLimit(1)
                    Spacer()
                    Text(timeAgo(inquiry.repliedAt ?? inquiry.createdAt))
                        .font(.system(size: 11))
                        .foregroundColor(.lcText3)
                }
                Text(inquiry.subject)
                    .font(.system(size: 13))
                    .foregroundColor(.lcText2)
                    .lineLimit(1)
                if let reply = inquiry.replyText, !reply.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.bubble.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.lcTeal)
                        Text(reply)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.lcTeal)
                            .lineLimit(1)
                    }
                } else {
                    Text("Awaiting reply")
                        .font(.system(size: 11))
                        .foregroundColor(.lcText3)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func timeAgo(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        switch diff {
        case ..<3600:  return "\(Int(diff / 60))m"
        case ..<86400: return "\(Int(diff / 3600))h"
        default:       return "\(Int(diff / 86400))d"
        }
    }
}

// MARK: - Detail (Member's perspective)

struct MemberInquiryDetailView: View {
    let inquiry: ChurchInquiry

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Church header
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.lcNavy.opacity(0.08))
                                .frame(width: 48, height: 48)
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.lcNavy)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(inquiry.churchName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.lcText)
                            Text(inquiry.inquiryType.fullLabel)
                                .font(.system(size: 12))
                                .foregroundColor(.lcText3)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(14)

                    // Your original message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR MESSAGE • \(inquiry.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.lcText3)
                            .tracking(0.5)
                        Text(inquiry.subject)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lcText)
                        Text(inquiry.body)
                            .font(.system(size: 14))
                            .foregroundColor(.lcText2)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(14)

                    // Reply (or pending state)
                    if let reply = inquiry.replyText, !reply.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.bubble.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.lcTeal)
                                Text("REPLY FROM \(inquiry.churchName.uppercased())")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.lcTeal)
                                    .tracking(0.5)
                                Spacer()
                                if let when = inquiry.repliedAt {
                                    Text(when.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 11))
                                        .foregroundColor(.lcText3)
                                }
                            }
                            Text(reply)
                                .font(.system(size: 15))
                                .foregroundColor(.lcText)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.lcTeal.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.lcTeal.opacity(0.25), lineWidth: 1)
                        )
                        .cornerRadius(14)
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "clock")
                                .foregroundColor(.lcText3)
                            Text("Awaiting reply from \(inquiry.churchName)")
                                .font(.system(size: 13))
                                .foregroundColor(.lcText3)
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.lcCream)
                        .cornerRadius(12)
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(Color.lcCream)
            .navigationTitle("Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.lcNavy)
                }
            }
        }
    }
}
