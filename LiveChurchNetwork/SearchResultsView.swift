import SwiftUI

enum SearchResultTab: String, CaseIterable {
    case all = "All"
    case churches = "Churches"
    case people = "People"
}

struct SearchResultsView: View {
    let searchQuery: String
    @EnvironmentObject var appState: AppState
    @ObservedObject var vm: DiscoverViewModel

    @State private var selectedTab: SearchResultTab = .all
    @State private var isLoadingMore = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with search query
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Search Results")
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                            Text("for \"\(searchQuery)\"")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    // Result counts
                    HStack(spacing: 16) {
                        resultCountPill("All", count: vm.browseChurches.count + vm.browsePeople.count)
                        resultCountPill("Churches", count: vm.browseChurches.count)
                        resultCountPill("People", count: vm.browsePeople.count)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                .background(Color.white)
                .border(Color(red: 229/255, green: 231/255, blue: 235/255), width: 0.5)

                // Tab picker
                Picker("Search Results", selection: $selectedTab) {
                    ForEach(SearchResultTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)

                // Content based on selected tab
                ZStack {
                    Color.white.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 0) {
                            if vm.browseChurches.isEmpty && vm.browsePeople.isEmpty {
                                emptyState
                            } else {
                                switch selectedTab {
                                case .all:
                                    allResultsContent
                                case .churches:
                                    churchesContent
                                case .people:
                                    peopleContent
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Content Views

    private var allResultsContent: some View {
        VStack(spacing: 16) {
            // Churches section
            if !vm.browseChurches.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Churches")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                        .padding(.horizontal, 20)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 18
                    ) {
                        ForEach(vm.browseChurches.prefix(4), id: \.id) { church in
                            NavigationLink(destination: ChurchDetailView(church: church)) {
                                PremiumChurchCard(
                                    church: church,
                                    initialIsFollowing: vm.followedChurchSlugs.contains(church.slug)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)

                    if vm.browseChurches.count > 4 {
                        NavigationLink("View All Churches (\(vm.browseChurches.count))") {
                            Text("") // Placeholder - handled by tab selection
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                        .padding(.vertical, 8)
                    }
                }
                .padding(.vertical, 16)
            }

            // People section
            if !vm.browsePeople.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("People")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                        .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        ForEach(vm.browsePeople.prefix(3), id: \.id) { person in
                            UserSearchResultCard(user: person)
                        }
                    }
                    .padding(.horizontal, 20)

                    if vm.browsePeople.count > 3 {
                        NavigationLink("View All People (\(vm.browsePeople.count))") {
                            Text("") // Placeholder
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                        .padding(.vertical, 8)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .padding(.vertical, 12)
    }

    private var churchesContent: some View {
        VStack(spacing: 0) {
            if vm.browseChurches.isEmpty {
                emptyState
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 18
                ) {
                    ForEach(vm.browseChurches, id: \.id) { church in
                        NavigationLink(destination: ChurchDetailView(church: church)) {
                            PremiumChurchCard(
                                church: church,
                                initialIsFollowing: vm.followedChurchSlugs.contains(church.slug)
                            )
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            if church.slug == vm.browseChurches.last?.slug {
                                Task { await vm.loadMoreChurches() }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                if vm.isLoadingMore {
                    ProgressView()
                        .tint(Color(red: 31/255, green: 60/255, blue: 136/255))
                        .padding(.vertical, 20)
                }
            }
        }
    }

    private var peopleContent: some View {
        VStack(spacing: 0) {
            if vm.browsePeople.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(vm.browsePeople, id: \.id) { person in
                        UserSearchResultCard(user: person)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

            Text("No results found")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

            Text("Try adjusting your search or filters")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }

    private func resultCountPill(_ label: String, count: Int) -> some View {
        VStack(spacing: 2) {
            Text(String(count))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(red: 243/255, green: 244/255, blue: 246/255))
        .cornerRadius(8)
    }
}

// MARK: - User Search Result Card

struct UserSearchResultCard: View {
    let user: DiscoverableUser
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationLink(destination: UserProfileView(userId: user.id)) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.1))

                    if let photoUrl = user.photoUrl, let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Text(String(user.name.prefix(1).uppercased()))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                            }
                        }
                        .clipShape(Circle())
                    } else {
                        Text(String(user.name.prefix(1).uppercased()))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                    }
                }
                .frame(width: 48, height: 48)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                    if let denomination = user.denomination {
                        Text(denomination)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    }
                }

                Spacer()

                // Follow button if authenticated
                if appState.currentUserId != nil {
                    FollowButton(
                        followingId: user.id.uuidString,
                        followingType: "worshipper",
                        initialIsFollowing: false
                    )
                    .frame(height: 28)
                }
            }
            .padding(12)
            .background(Color.white)
            .border(Color(red: 229/255, green: 231/255, blue: 235/255), width: 1)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SearchResultsView(
        searchQuery: "grace",
        vm: DiscoverViewModel()
    )
    .environmentObject(AppState())
}
