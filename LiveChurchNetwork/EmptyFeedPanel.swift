import SwiftUI

// MARK: - Empty Feed Panel
//
// Replaces the dead "Follow some churches" empty state with two actionable
// rails — nearby churches and suggested people — each with one-tap follow.
// Mirrors the web `<EmptyFeedPanel>` so behavior is identical across
// platforms.
//
// Source data:
//   - Churches: AppState.approvedChurches, ranked by city match.
//   - People:  SupabaseService.getDiscoverableWorshippers, filtered to
//              the viewer's denomination first, then padded with anyone.
//
// On the first successful follow we collapse the panel into a "You're set
// up — refresh feed" prompt; tapping the prompt triggers the parent's
// reload closure.

struct EmptyFeedPanel: View {
    /// Called when the user taps "Refresh feed" after their first follow.
    let onRefresh: () async -> Void

    @EnvironmentObject private var appState: AppState

    @State private var nearbyChurches: [ChurchSubmission] = []
    @State private var suggestedPeople: [Profile] = []
    @State private var loading = true
    @State private var followedSomething = false

    var body: some View {
        VStack(spacing: 14) {
            if followedSomething {
                successCard
            } else {
                welcomeCard
                if loading {
                    LCListSkeleton(rows: 3)
                } else {
                    if !nearbyChurches.isEmpty {
                        churchesRail
                    }
                    if !suggestedPeople.isEmpty {
                        peopleRail
                    }
                    if nearbyChurches.isEmpty && suggestedPeople.isEmpty {
                        fallbackCard
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .task { await load() }
    }

    // MARK: - Cards

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🌱")
                .font(.system(size: 26))
            Text("Welcome — let's build your feed")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.lcText)
            Text("Follow a few churches and people you know. Tap one below to start.")
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
    }

    private var successCard: some View {
        VStack(spacing: 10) {
            Text("🎉").font(.system(size: 30))
            Text("You're set up.")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lcText)
            Text("Refresh to see posts from the people and churches you just followed.")
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Button {
                Task { await onRefresh() }
            } label: {
                Text("Refresh feed")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.lcNavy)
                    .cornerRadius(10)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.lcTeal.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.lcTeal.opacity(0.3), lineWidth: 1)
        )
    }

    private var churchesRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Churches near you")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lcText)
                Spacer()
                NavigationLink(destination: DirectoryView().environmentObject(appState)) {
                    Text("See all →")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.lcNavy)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(nearbyChurches.prefix(8)) { church in
                        ChurchSuggestionCard(
                            church: church,
                            onFollowed: { followedSomething = true }
                        )
                        .environmentObject(appState)
                    }
                }
                .padding(.horizontal, 1) // avoid border clipping
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
    }

    private var peopleRail: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("People you might know")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.lcText)
                .padding(.bottom, 4)
            VStack(spacing: 0) {
                ForEach(suggestedPeople.prefix(5)) { person in
                    PersonSuggestionRow(
                        person: person,
                        onFollowed: { followedSomething = true }
                    )
                    .environmentObject(appState)
                    if person.id != suggestedPeople.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
    }

    private var fallbackCard: some View {
        LCEmptyState(
            icon: "newspaper",
            title: "Your feed is getting started",
            subtitle: "We don't have local suggestions yet — head to Discover to find churches and people to follow."
        )
    }

    // MARK: - Data

    private func load() async {
        loading = true
        defer { loading = false }

        let myCity = appState.profile?.city?.lowercased() ?? ""
        let myDenomination = appState.profile?.denomination

        // Churches: rank approved churches by city match, then fall back to
        // anything else so a transplant or fresh signup still sees options.
        let churches = appState.approvedChurches
        let nearby = churches.filter {
            ($0.city ?? "").lowercased() == myCity && !myCity.isEmpty
        }
        let others = churches.filter {
            ($0.city ?? "").lowercased() != myCity || myCity.isEmpty
        }
        nearbyChurches = Array((nearby + others).prefix(12))

        // People: prefer denomination matches, fall back to anyone.
        do {
            let everyone = try await SupabaseService.shared.getDiscoverableWorshippers()
            // Drop the viewer themselves.
            let pool = everyone.filter { $0.id != appState.currentUserId }
            let denomMatches = pool.filter { p in
                guard let d = myDenomination, !d.isEmpty else { return false }
                return (p.denomination ?? "").lowercased() == d.lowercased()
            }
            suggestedPeople = Array((denomMatches + pool.filter { p in
                !denomMatches.contains(where: { $0.id == p.id })
            }).prefix(8))
        } catch {
            print("[EmptyFeedPanel] suggested people failed: \(error.localizedDescription)")
            suggestedPeople = []
        }
    }
}

// MARK: - Church suggestion card

private struct ChurchSuggestionCard: View {
    let church: ChurchSubmission
    let onFollowed: () -> Void

    @EnvironmentObject private var appState: AppState
    @State private var isFollowing = false
    @State private var busy = false

    private var slug: String {
        (church.churchName ?? "")
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
    }

    var body: some View {
        VStack(spacing: 8) {
            avatar
            Text(church.churchName ?? "Church")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.lcText)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text([church.city, church.state].compactMap { $0 }.joined(separator: ", "))
                .font(.system(size: 10))
                .foregroundColor(.lcText3)
                .lineLimit(1)
            Button { Task { await follow() } } label: {
                Text(isFollowing ? "✓ Following" : (busy ? "…" : "Follow"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isFollowing ? .lcText3 : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(isFollowing ? Color.lcCream : Color.lcNavy)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(isFollowing || busy)
        }
        .padding(10)
        .frame(width: 140)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
        .cornerRadius(12)
    }

    @ViewBuilder
    private var avatar: some View {
        if let urlStr = church.avatarUrl, !urlStr.isEmpty, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    placeholder
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.lcNavy.opacity(0.10)
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            Text((church.churchName ?? "✝").prefix(1).uppercased())
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.lcNavy)
        }
    }

    private func follow() async {
        guard let uid = appState.currentUserId, !slug.isEmpty else { return }
        busy = true
        do {
            try await SupabaseService.shared.follow(
                followerId: uid,
                followingId: slug,
                followingType: "church"
            )
            isFollowing = true
            onFollowed()
        } catch {
            print("[EmptyFeedPanel] follow church failed: \(error.localizedDescription)")
        }
        busy = false
    }
}

// MARK: - Person suggestion row

private struct PersonSuggestionRow: View {
    let person: Profile
    let onFollowed: () -> Void

    @EnvironmentObject private var appState: AppState
    @State private var isFollowing = false
    @State private var busy = false

    var body: some View {
        HStack(spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text(person.fullName ?? "—")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText)
                    .lineLimit(1)
                Text([person.city, person.denomination].compactMap { $0 }.joined(separator: " · "))
                    .font(.system(size: 11))
                    .foregroundColor(.lcText3)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Button { Task { await follow() } } label: {
                Text(isFollowing ? "✓" : (busy ? "…" : "Follow"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isFollowing ? .lcText3 : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(isFollowing ? Color.lcCream : Color.lcNavy)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(isFollowing || busy)
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var avatar: some View {
        if let urlStr = person.photoUrl, !urlStr.isEmpty, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    placeholder
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.lcNavy.opacity(0.10)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            Text((person.fullName ?? "?").prefix(1).uppercased())
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.lcNavy)
        }
    }

    private func follow() async {
        guard let uid = appState.currentUserId else { return }
        busy = true
        do {
            try await SupabaseService.shared.follow(
                followerId: uid,
                followingId: person.id.uuidString,
                followingType: "worshipper"
            )
            isFollowing = true
            onFollowed()
        } catch {
            print("[EmptyFeedPanel] follow person failed: \(error.localizedDescription)")
        }
        busy = false
    }
}
