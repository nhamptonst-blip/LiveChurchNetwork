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
                Spacer()
                ProgressView().tint(.lcNavy)
                Spacer()
            } else if let err = errorMessage {
                errorState(err)
            } else if filtered.isEmpty {
                emptyState
            } else {
                inquiryList
            }
        }
        .background(Color.lcCream)
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedInquiry) { inquiry in
            InquiryDetailView(inquiry: inquiry) { updated in
                if let idx = inquiries.firstIndex(where: { $0.id == updated.id }) {
                    inquiries[idx] = updated
                }
                selectedInquiry = nil
            }
        }
        .task { await load() }
    }

    // MARK: - Filter bars

    private var statusFilterBar: some View {
        HStack(spacing: 0) {
            statusPill(label: "New\(newCount > 0 ? " (\(newCount))" : "")", status: .new)
            statusPill(label: "Replied",  status: .replied)
            statusPill(label: "Archived", status: .archived)
            statusPill(label: "All",      status: nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
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

    @Environment(\.dismiss) private var dismiss
    @State private var isUpdating = false

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

                    // Actions
                    if inquiry.inquiryStatus != .archived {
                        VStack(spacing: 10) {
                            if inquiry.inquiryStatus == .new {
                                actionButton(
                                    label: "Mark as Replied",
                                    icon: "checkmark.circle",
                                    color: .lcTeal
                                ) { await updateStatus(.replied) }
                            }
                            actionButton(
                                label: "Archive",
                                icon: "archivebox",
                                color: .lcText3
                            ) { await updateStatus(.archived) }
                        }
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
        }
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
