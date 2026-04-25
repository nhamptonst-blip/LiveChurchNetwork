import SwiftUI

struct DirectoryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = DiscoverViewModel()

    private var isInBrowseMode: Bool {
        !vm.churchSearch.isEmpty || !vm.activeFilters.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        // MARK: - Header & Search
                        headerSection
                            .padding(.vertical, 16)
                            .background(Color.white)

                        // MARK: - Churches Content
                        churchesSection
                    }
                }
                .background(Color.white)
            }
        }
        .task { await vm.loadInitialData(appState: appState) }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Find a Church")
                .font(.system(size: 34, weight: .black))
                .foregroundColor(.lcText)

            Text("Discover churches, livestreams, and faith communities around the world.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.lcText2)

            // Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.lcText3)
                    .font(.system(size: 16))

                TextField("Search by church, pastor, city, denomination...",
                         text: $vm.churchSearch)
                    .font(.system(size: 15))
                    .submitLabel(.search)
                    .onSubmit { Task { await vm.reloadChurchesWithFilters() } }

                if !vm.churchSearch.isEmpty {
                    Button {
                        vm.churchSearch = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.lcText3)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(red: 0.96, green: 0.96, blue: 0.96))
            .cornerRadius(14)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Churches Section
    private var churchesSection: some View {
        VStack(spacing: 0) {
            // Live stories row
            if !vm.liveNowChurches.isEmpty {
                LiveStoriesRow(liveChurches: vm.liveNowChurches)
                    .padding(.vertical, 12)
            }

            // Filter pills
            FilterPillRow(activeFilters: $vm.activeFilters)
                .padding(.vertical, 12)

            // Curated or browse content
            if vm.isCuratedLoading {
                loadingGrid
            } else if isInBrowseMode {
                browseSection("All Churches", churches: vm.browseChurches)
            } else {
                curatedSections
            }
        }
    }

    // MARK: - Curated Sections
    private var curatedSections: some View {
        VStack(spacing: 0) {
            // Live Now
            if !vm.liveNowChurches.isEmpty {
                churchGrid("🔴 Live Now", churches: vm.liveNowChurches)
            }

            // Trending
            if !vm.trendingChurches.isEmpty {
                churchGrid("🔥 Trending This Week", churches: vm.trendingChurches)
            }

            // New This Week
            if !vm.newThisWeek.isEmpty {
                churchGrid("✨ New This Week", churches: vm.newThisWeek)
            }

            // Recommended
            if !vm.recommendedChurches.isEmpty {
                churchGrid("⭐ Recommended For You", churches: vm.recommendedChurches)
            }

            // All Churches
            browseSection("All Churches", churches: vm.browseChurches)
        }
    }

    // MARK: - Browse Section (Paginated)
    private func browseSection(_ title: String, churches: [Church]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(title)

            if churches.isEmpty && !vm.isCuratedLoading {
                DiscoverEmptyState(
                    icon: "magnifyingglass",
                    title: "No matches",
                    subtitle: "Try adjusting your filters"
                )
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(churches, id: \.slug) { church in
                        NavigationLink(destination: ChurchDetailView(church: church)) {
                            PremiumChurchCard(
                                church: church,
                                initialIsFollowing: vm.followedChurchSlugs.contains(church.slug)
                            )
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            if church.slug == churches.last?.slug {
                                Task { await vm.loadMoreChurches() }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                if vm.isLoadingMore {
                    ProgressView()
                        .tint(.lcNavy)
                        .padding(.vertical, 20)
                }
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Church Grid Section
    private func churchGrid(_ title: String, churches: [Church]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(title)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(churches, id: \.slug) { church in
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
        }
        .padding(.vertical, 20)
    }

    // MARK: - Loading Grid
    private var loadingGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Loading...")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(0..<6, id: \.self) { _ in
                    ChurchDiscoveryCardSkeleton()
                        .frame(height: 240)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }


    // MARK: - Section Label Helper
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .black))
            .foregroundColor(.lcText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }
}

#Preview {
    DirectoryView()
        .environmentObject(AppState())
}
