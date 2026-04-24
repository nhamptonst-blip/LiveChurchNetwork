import SwiftUI
import Supabase

struct AdminDashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var allProfiles: [Profile] = []
    @State private var allSubmissions: [ChurchSubmission] = []
    @State private var isLoading = true
    @State private var selectedTab = 0
    @State private var showSignOutAlert = false
    @State private var actionError: String?
    @State private var isSeeding = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...").tint(.lcNavy)
                } else {
                    mainContent
                }
            }
            .background(Color.lcCream)
            .navigationTitle("God Mode")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) { showSignOutAlert = true } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "bolt.fill").foregroundColor(.lcGold)
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { await appState.signOut() }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Action Failed", isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )) {
                Button("OK", role: .cancel) { actionError = nil }
            } message: {
                Text(actionError ?? "")
            }
        }
        .task { await loadAll() }
    }

    // MARK: Main content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                statsRow
                debugSection
                pendingChurchesSection
                allUsersSection
                liveChurchesSection
            }
            .padding(16)
        }
    }

    private var debugSection: some View {
        VStack(spacing: 12) {
            Text("Debug Tools").font(.system(size: 14, weight: .bold)).foregroundColor(.lcText3)
            Button {
                isSeeding = true
                Task {
                    do {
                        try await SupabaseService.shared.cleanAndSeedDatabase(adminUserId: appState.currentUserId)
                        await loadAll()
                        actionError = "✅ Database seeded! Your admin account preserved."
                    } catch {
                        actionError = "❌ Seeding failed: \(error.localizedDescription)"
                    }
                    isSeeding = false
                }
            } label: {
                HStack {
                    if isSeeding {
                        ProgressView().tint(.orange)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isSeeding ? "Seeding..." : "Clean & Seed Database")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.orange)
            }
            .disabled(isSeeding)
        }
    }

    // MARK: Stats row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(allProfiles.count)", label: "Users",
                     icon: "person.2.fill", color: .lcNavy)
            StatCard(value: "\(allSubmissions.count)", label: "Churches",
                     icon: "building.2.fill", color: .lcTeal)
            StatCard(value: "\(allSubmissions.filter { $0.isLive }.count)", label: "Live Now",
                     icon: "antenna.radiowaves.left.and.right", color: .red)
        }
    }

    // MARK: Pending churches

    private var pendingChurchesSection: some View {
        let pending = allSubmissions.filter { $0.status == "pending" }
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Pending Approval",
                         subtitle: "\(pending.count) waiting")

            if pending.isEmpty {
                Text("No pending churches")
                    .font(.system(size: 13))
                    .foregroundColor(.lcText3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(12)
            } else {
                ForEach(pending) { sub in
                    AdminChurchRow(submission: sub) { action in
                        await handleAction(action, submissionId: sub.id)
                    }
                }
            }
        }
    }

    // MARK: All users

    private var allUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "All Users", subtitle: "\(allProfiles.count) total")

            ForEach(allProfiles) { profile in
                NavigationLink(destination: destinationView(for: profile)) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.lcNavy).frame(width: 36, height: 36)
                            Text(profile.fullName?.prefix(1).uppercased() ?? "?")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(.lcGold)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.fullName ?? "Unknown")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.lcText)
                            Text(profile.role ?? "worshipper")
                                .font(.system(size: 11))
                                .foregroundColor(.lcText3)
                        }
                        Spacer()
                        RoleBadge(role: profile.role ?? "worshipper")
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func destinationView(for profile: Profile) -> some View {
        Group {
            if profile.role == "church_admin" {
                // Find the church submission for this admin and navigate to church detail
                if let submission = allSubmissions.first(where: { $0.userId == profile.id }) {
                    let church = Church(
                        name: submission.churchName ?? "",
                        slug: (submission.churchName ?? "").lowercased().replacingOccurrences(of: " ", with: "-"),
                        image: "",
                        denomination: submission.denomination ?? "",
                        permalink: "",
                        phone: submission.phone ?? "",
                        website: submission.website ?? "",
                        serviceTimes: submission.serviceTimes ?? "",
                        about: submission.about ?? "",
                        isLive: submission.isLive
                    )
                    ChurchDetailView(church: church)
                } else {
                    Text("Church not found")
                        .font(.system(size: 14, weight: .semibold))
                }
            } else {
                // Navigate to worshipper profile
                UserProfileView(userId: profile.id)
            }
        }
    }

    // MARK: Live churches

    private var liveChurchesSection: some View {
        let live = allSubmissions.filter { $0.isLive }
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Currently Live", subtitle: "\(live.count) streaming")

            if live.isEmpty {
                Text("No churches are live right now")
                    .font(.system(size: 13))
                    .foregroundColor(.lcText3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(12)
            } else {
                ForEach(live) { sub in
                    HStack {
                        LiveBadge()
                        Text(sub.churchName ?? "Unnamed Church")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.2), lineWidth: 1))
                }
            }
        }
    }

    // MARK: Actions

    private func handleAction(_ action: String, submissionId: UUID) async {
        let newStatus = action == "approve" ? "approved" : "rejected"
        do {
            let updated: [ChurchSubmission] = try await SupabaseService.shared.client
                .from("church_submissions")
                .update(["status": newStatus])
                .eq("id", value: submissionId.uuidString)
                .select()
                .execute()
                .value
            if updated.isEmpty {
                actionError = "No rows were updated. This usually means a Row Level Security policy is blocking the update. Add an UPDATE policy on church_submissions that allows the admin role."
                return
            }
            await loadAll()
        } catch {
            actionError = "Could not \(action) church: \(error.localizedDescription)"
        }
    }

    private func loadAll() async {
        isLoading = true
        do {
            allProfiles = try await SupabaseService.shared.client
                .from("profiles")
                .select()
                .execute()
                .value

            allSubmissions = try await SupabaseService.shared.client
                .from("church_submissions")
                .select()
                .execute()
                .value
        } catch {
            print("Admin load error: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Admin church row

struct AdminChurchRow: View {
    let submission: ChurchSubmission
    let onAction: (String) async -> Void
    @State private var isActing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(submission.churchName ?? "Unnamed Church")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lcText)
                Spacer()
                Text("PENDING")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(20)
            }

            if let denom = submission.denomination, !denom.isEmpty {
                Text(denom).font(.system(size: 11)).foregroundColor(.lcText3)
            }

            HStack(spacing: 10) {
                Button {
                    isActing = true
                    Task { await onAction("approve"); isActing = false }
                } label: {
                    Text("Approve")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                }

                Button {
                    isActing = true
                    Task { await onAction("reject"); isActing = false }
                } label: {
                    Text("Reject")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
            .disabled(isActing)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Stat card

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.lcText)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.lcText3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
    }
}

// MARK: - Role badge

struct RoleBadge: View {
    let role: String

    var color: Color {
        switch role {
        case "admin":       return .purple
        case "church_admin": return .lcNavy
        default:            return .lcText3
        }
    }

    var body: some View {
        Text(role)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .cornerRadius(20)
    }
}
