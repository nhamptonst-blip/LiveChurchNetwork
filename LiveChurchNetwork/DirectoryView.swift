import SwiftUI
import UIKit

struct DirectoryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = DiscoverViewModel()
    @State private var selectedTab: DiscoverTab = .churches
    @State private var isSearchFocused = false
    @State private var activeFilters: Set<String> = []

    enum DiscoverTab {
        case churches
        case people
    }

    private let quickFilters = ["Live Now", "Near Me", "Trending", "Non-Denominational", "Baptist", "Catholic", "Pentecostal", "More Filters"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Find")
                            .font(.system(size: 34, weight: .black))
                            .tracking(-0.6)
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                        Text("Find churches, livestreams, and people of faith.")
                            .font(.system(size: 16, weight: .medium))
                            .lineSpacing(6)
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    .background(Color.white)

                    // MARK: - Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                        TextField("Search churches, people, pastors, cities...", text: $vm.churchSearch)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .submitLabel(.search)
                            .onSubmit {
                                Task { await vm.reloadChurchesWithFilters() }
                            }

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
                    .border(
                        Color(red: 229/255, green: 231/255, blue: 235/255),
                        width: 1
                    )
                    .cornerRadius(18)
                    .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.06), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // MARK: - Segmented Control
                    Picker("Find Tab", selection: $selectedTab) {
                        Text("Churches").tag(DiscoverTab.churches)
                        Text("People").tag(DiscoverTab.people)
                    }
                    .pickerStyle(.segmented)
                    .frame(height: 44)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .background(Color.white)
                    // Custom segmented control styling
                    .onAppear {
                        let appearance = UISegmentedControl.appearance()
                        appearance.selectedSegmentTintColor = UIColor.white
                        appearance.setBackgroundImage(
                            UIImage(color: UIColor(red: 243/255, green: 244/255, blue: 246/255, alpha: 1)),
                            for: .normal,
                            barMetrics: .default
                        )
                        appearance.setDividerImage(
                            UIImage(),
                            forLeftSegmentState: .normal,
                            rightSegmentState: .normal,
                            barMetrics: .default
                        )
                        let normalTextAttrs: [NSAttributedString.Key: Any] = [
                            .foregroundColor: UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1),
                            .font: UIFont.systemFont(ofSize: 15, weight: .bold)
                        ]
                        let selectedTextAttrs: [NSAttributedString.Key: Any] = [
                            .foregroundColor: UIColor(red: 31/255, green: 60/255, blue: 136/255, alpha: 1),
                            .font: UIFont.systemFont(ofSize: 15, weight: .bold)
                        ]
                        appearance.setTitleTextAttributes(normalTextAttrs, for: .normal)
                        appearance.setTitleTextAttributes(selectedTextAttrs, for: .selected)
                    }

                    // MARK: - Content
                    ScrollView {
                        if selectedTab == .churches {
                            churchesContent
                        } else {
                            peopleContent
                        }
                    }
                    .background(Color.white)
                }
            }
        }
        .task { await vm.loadInitialData(appState: appState) }
    }

    // MARK: - Churches Content
    private var churchesContent: some View {
        VStack(spacing: 0) {
            if vm.isCuratedLoading {
                loadingGrid
            } else {
                // MARK: - 1. Quick Filter Row
                quickFilterRow
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                // MARK: - 2. Featured Churches (Premium Horizontal Scroll)
                if !vm.trendingChurches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Featured Churches")
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                            Text("Handpicked communities to explore")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                        }
                        .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(vm.trendingChurches.prefix(8), id: \.slug) { church in
                                    NavigationLink(destination: ChurchDetailView(church: church)) {
                                        FeaturedChurchCard(
                                            church: church,
                                            initialIsFollowing: vm.followedChurchSlugs.contains(church.slug)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                                    .frame(width: 0)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }

                // MARK: - 3. Live Now
                if !vm.liveNowChurches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Live Now")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        churchGrid(vm.liveNowChurches.prefix(2).map { $0 })
                    }
                    .padding(.vertical, 20)
                }

                // MARK: - 4. Churches Near You
                if !vm.recentlyAdded.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Churches Near You")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        churchGrid(vm.recentlyAdded.prefix(2).map { $0 })
                    }
                    .padding(.vertical, 20)
                }

                // MARK: - 5. Browse by Denomination
                if !vm.browseChurches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Browse by Denomination")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        churchGrid(vm.browseChurches.prefix(4).map { $0 })
                    }
                    .padding(.vertical, 20)
                }

                // MARK: - 6. Browse All Churches
                if !vm.browseChurches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Browse All Churches")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        churchGrid(vm.browseChurches)
                    }
                    .padding(.vertical, 20)
                }

                if vm.browseChurches.isEmpty {
                    DiscoverEmptyState(
                        icon: "building.2",
                        title: "No churches found",
                        subtitle: "Try adjusting your search"
                    )
                    .padding(.vertical, 40)
                }
            }
        }
    }

    // MARK: - Quick Filter Row
    private var quickFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickFilters, id: \.self) { filter in
                    QuickFilterChip(
                        label: filter,
                        isActive: activeFilters.contains(filter),
                        hasRedDot: filter == "Live Now"
                    ) {
                        if activeFilters.contains(filter) {
                            activeFilters.remove(filter)
                        } else {
                            activeFilters.insert(filter)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - People Content
    private var peopleContent: some View {
        VStack(spacing: 0) {
            if vm.isCuratedLoading {
                loadingPeopleGrid
            } else if vm.browsePeople.isEmpty {
                DiscoverEmptyState(
                    icon: "person.2",
                    title: "No worshippers found",
                    subtitle: "Check back later"
                )
                .padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    if !vm.suggestedPeople.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggested for You")
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)

                            peopleGrid(Array(vm.suggestedPeople.prefix(6)))
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("More Worshippers")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        peopleGrid(vm.browsePeople)
                    }
                }
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Church Grid
    private func churchGrid(_ churches: [Church]) -> some View {
        VStack(spacing: 14) {
            ForEach(0..<((churches.count + 1) / 2), id: \.self) { rowIndex in
                let leftIndex = rowIndex * 2
                let rightIndex = leftIndex + 1

                HStack(spacing: 14) {
                    NavigationLink(destination: ChurchDetailView(church: churches[leftIndex])) {
                        PremiumChurchCard(
                            church: churches[leftIndex],
                            initialIsFollowing: vm.followedChurchSlugs.contains(churches[leftIndex].slug)
                        )
                        .frame(height: 240)
                    }
                    .buttonStyle(.plain)

                    if rightIndex < churches.count {
                        NavigationLink(destination: ChurchDetailView(church: churches[rightIndex])) {
                            PremiumChurchCard(
                                church: churches[rightIndex],
                                initialIsFollowing: vm.followedChurchSlugs.contains(churches[rightIndex].slug)
                            )
                            .frame(height: 240)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Spacer()
                    }
                }
                .onAppear {
                    if rightIndex >= churches.count {
                        Task { await vm.loadMoreChurches() }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - People Grid
    private func peopleGrid(_ people: [DiscoverableUser]) -> some View {
        VStack(spacing: 14) {
            ForEach(0..<((people.count + 1) / 2), id: \.self) { rowIndex in
                let leftIndex = rowIndex * 2
                let rightIndex = leftIndex + 1

                HStack(spacing: 14) {
                    NavigationLink(destination: UserProfileView(userId: people[leftIndex].id)) {
                        PeopleDiscoveryCard(
                            user: people[leftIndex],
                            initialIsFollowing: vm.followedUserIds.contains(people[leftIndex].id.uuidString)
                        )
                        .frame(height: 250)
                    }
                    .buttonStyle(.plain)

                    if rightIndex < people.count {
                        NavigationLink(destination: UserProfileView(userId: people[rightIndex].id)) {
                            PeopleDiscoveryCard(
                                user: people[rightIndex],
                                initialIsFollowing: vm.followedUserIds.contains(people[rightIndex].id.uuidString)
                            )
                            .frame(height: 250)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Spacer()
                    }
                }
                .onAppear {
                    if rightIndex >= people.count {
                        Task { await vm.loadMorePeople() }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Loading States
    private var loadingGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Loading...")
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            VStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 14) {
                        ChurchDiscoveryCardSkeleton()
                            .frame(height: 240)
                        ChurchDiscoveryCardSkeleton()
                            .frame(height: 240)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }

    private var loadingPeopleGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Loading...")
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            VStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 14) {
                        PeopleDiscoveryCardSkeleton()
                            .frame(height: 250)
                        PeopleDiscoveryCardSkeleton()
                            .frame(height: 250)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    DirectoryView()
        .environmentObject(AppState())
}

// MARK: - Quick Filter Chip

struct QuickFilterChip: View {
    let label: String
    let isActive: Bool
    let hasRedDot: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if hasRedDot && isActive {
                    Circle()
                        .fill(Color(red: 239/255, green: 68/255, blue: 68/255))
                        .frame(width: 8, height: 8)
                }

                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isActive ? .white : Color(red: 55/255, green: 65/255, blue: 81/255))
            .frame(height: 38)
            .padding(.horizontal, 14)
            .background(isActive ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
            .border(
                isActive
                    ? Color(red: 31/255, green: 60/255, blue: 136/255)
                    : Color(red: 229/255, green: 231/255, blue: 235/255),
                width: 1
            )
            .cornerRadius(999)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helper for Segmented Control Background Color

extension UIImage {
    convenience init(color: UIColor) {
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!)
    }
}
