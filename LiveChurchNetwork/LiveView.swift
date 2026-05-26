import SwiftUI

/// Live tab — shows every approved church currently broadcasting (`is_live = true`).
/// Pulls from the same `getLiveChurches()` query the feed banner uses, so the
/// two surfaces stay in lockstep.
struct LiveView: View {
    @EnvironmentObject var appState: AppState
    @State private var churches: [ChurchSubmission] = []
    @State private var loading = true
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.lcCream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        if loading && churches.isEmpty {
                            loadingState
                        } else if let err = loadError {
                            errorState(err)
                        } else if churches.isEmpty {
                            emptyState
                        } else {
                            liveList
                        }
                    }
                    .padding(.bottom, 40)
                }
                .refreshable { await load(force: true) }
            }
            .navigationBarHidden(true)
        }
        .task { await load() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Live")
                .font(.system(size: 34, weight: .heavy))
                .foregroundColor(.lcText)
            HStack(spacing: 6) {
                if !churches.isEmpty {
                    pulsingDot
                    Text("\(churches.count) church\(churches.count == 1 ? "" : "es") streaming now")
                        .font(.system(size: 14))
                        .foregroundColor(.lcText2)
                } else {
                    Text("Watch live services from churches in your community")
                        .font(.system(size: 14))
                        .foregroundColor(.lcText3)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    // MARK: - List

    private var liveList: some View {
        VStack(spacing: 12) {
            ForEach(churches) { church in
                liveCard(church)
            }
        }
        .padding(.horizontal, 16)
    }

    private func liveCard(_ church: ChurchSubmission) -> some View {
        // Tap → in-app ChurchDetailView. The profile contains the Watch Live
        // button that opens the actual stream — keeps users inside the app
        // on first tap instead of ejecting them to YouTube/Twitch.
        NavigationLink(destination: ChurchDetailView(church: directoryChurch(from: church))) {
            HStack(alignment: .top, spacing: 14) {
                avatar(for: church)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        pulsingDot
                        Text("LIVE NOW")
                            .font(.system(size: 10, weight: .black))
                            .tracking(0.8)
                            .foregroundColor(.red)
                    }
                    Text(church.churchName ?? "Church")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.lcText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if let location = locationString(for: church) {
                        Text(location)
                            .font(.system(size: 12))
                            .foregroundColor(.lcText3)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(Color.red))
            }
            .padding(14)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    /// Bridge from the persisted `ChurchSubmission` into the directory-style
    /// `Church` value that `ChurchDetailView` expects. Mirrors the helper
    /// inside `ChurchAdminDashboardView.makePreviewChurch(from:)`.
    private func directoryChurch(from sub: ChurchSubmission) -> Church {
        let name = sub.churchName ?? ""
        let slug = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
        var c = Church(
            name: name,
            slug: slug,
            image: sub.avatarUrl ?? "",
            denomination: sub.denomination ?? "",
            permalink: "",
            phone: sub.phone ?? "",
            website: sub.website ?? "",
            serviceTimes: sub.serviceTimes ?? "",
            about: sub.about ?? "",
            isLive: sub.isLive
        )
        c.email = sub.contactEmail ?? ""
        c.address = sub.addressLine ?? ""
        c.donationUrl = sub.donationUrl ?? ""
        c.isVerified = sub.status == "approved"
        c.city = sub.city ?? ""
        c.coverImage = sub.coverUrl ?? ""
        c.pastorName = sub.pastorName ?? ""
        c.livestreamUrl = sub.livestreamUrl ?? ""
        return c
    }

    private func avatar(for church: ChurchSubmission) -> some View {
        Group {
            if let urlString = church.avatarUrl, let url = URL(string: urlString), !urlString.isEmpty {
                AsyncImage(url: url) { phase in
                    if let img = phase.image { img.resizable().scaledToFill() }
                    else { initialFallback(for: church) }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                initialFallback(for: church)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func initialFallback(for church: ChurchSubmission) -> some View {
        let letter = String(church.churchName?.first.map { String($0) } ?? "C").uppercased()
        return ZStack {
            RoundedRectangle(cornerRadius: 14).fill(Color.lcNavy)
            Text(letter).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
        }
    }

    private func locationString(for church: ChurchSubmission) -> String? {
        let parts = [church.city, church.state].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private var pulsingDot: some View {
        TimelineView(.periodic(from: .now, by: 0.9)) { ctx in
            let phase = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 0.9) / 0.9
            ZStack {
                Circle()
                    .stroke(Color.red.opacity(1.0 - phase), lineWidth: 4)
                    .scaleEffect(1.0 + (1.2 * phase))
                Circle().fill(Color.red).frame(width: 8, height: 8)
            }
            .frame(width: 18, height: 18)
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView().tint(.lcNavy)
            Text("Looking for live services…")
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.circle")
                .font(.system(size: 48))
                .foregroundColor(.lcNavy.opacity(0.6))
            Text("No live services right now")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lcText)
            Text("Pull down to refresh, or check back when your church goes on air.")
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.red)
            Text("Couldn't load live services")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.lcText)
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            Button("Retry") { Task { await load(force: true) } }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.lcNavy)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Load

    private func load(force: Bool = false) async {
        if !force { loading = true }
        loadError = nil
        do {
            let result = try await SupabaseService.shared.getLiveChurches()
            churches = result
        } catch {
            loadError = error.localizedDescription
        }
        loading = false
    }
}

#Preview {
    LiveView().environmentObject(AppState())
}
