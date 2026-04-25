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
        VStack(alignment: .leading, spacing: 0) {
            // Title: 34px, weight 800, color #111827, letter-spacing -0.6px
            Text("Find a Church")
                .font(.system(size: 34, weight: .heavy))
                .tracking(-0.6)
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

            // Subtitle: 16px, weight 500, color #6B7280, line-height 22px
            // Top margin: 4px
            Text("Discover churches, livestreams, and faith communities around the world.")
                .font(.system(size: 16, weight: .medium))
                .lineSpacing(6)
                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                .padding(.top, 4)

            // Search Bar (Phase 4 styling)
            // Top margin: 20px, Height: 54px, Border radius: 18px
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                TextField("Search by church, pastor, city, denomination...",
                         text: $vm.churchSearch)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                    .submitLabel(.search)
                    .onSubmit { Task { await vm.reloadChurchesWithFilters() } }

                if !vm.churchSearch.isEmpty {
                    Button {
                        vm.churchSearch = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.white)
            .border(Color(red: 229/255, green: 231/255, blue: 235/255), width: 1)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            .padding(.top, 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
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
