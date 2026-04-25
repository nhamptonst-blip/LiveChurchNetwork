import SwiftUI
import UIKit

struct DirectoryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = DiscoverViewModel()
    @State private var selectedTab: DiscoverTab = .churches
    @State private var isSearchFocused = false
    @State private var activeFilters: Set<String> = []
    @State private var locationEnabled = false
    @State private var selectedDenomination: String? = nil
    @State private var selectedPeopleFilter: String = "Suggested"
    @State private var searchQuery: String = ""
    @State private var searchResultsChurches: [Church] = []
    @State private var searchResultsPeople: [DiscoverableUser] = []
    @State private var selectedSearchTab: String = "All"
    @State private var isSearching: Bool = false
    @State private var showChurchFilterSheet: Bool = false
    @State private var showPeopleFilterSheet: Bool = false
    @State private var churchFilters: ChurchFilters = ChurchFilters()
    @State private var peopleFilters: PeopleFilters = PeopleFilters()

    private let denominationCategories = [
        "Non-Denominational", "Baptist", "Catholic", "Pentecostal",
        "Methodist", "Lutheran", "Presbyterian", "Orthodox",
        "Anglican", "Evangelical"
    ]

    private let peopleFilterOptions = ["Suggested", "Near Me", "From My Churches", "New Members", "Leaders", "Mutuals"]

    // MARK: - Computed Filter Properties
    private var filteredBrowseChurches: [Church] {
        var churches = selectedDenomination.map { denom in
            vm.browseChurches.filter { $0.denomination == denom }
        } ?? vm.browseChurches

        // Apply ChurchFilters
        if !churchFilters.isEmpty {
            // Filter by denominations
            if !churchFilters.denominations.isEmpty {
                churches = churches.filter { churchFilters.denominations.contains($0.denomination) }
            }

            // Filter by location (simplified: "Near Me" or "Anywhere")
            if churchFilters.location.contains("Near Me") && !locationEnabled {
                churches = churches.prefix(10).map { $0 }
            }
        }

        return churches
    }

    private var filteredBrowsePeople: [DiscoverableUser] {
        var people = vm.browsePeople

        // Apply PeopleFilters
        if !peopleFilters.isEmpty {
            if peopleFilters.nearMe {
                // Filter to nearby people (simplified: just reduce list for now)
                people = people.prefix(Int(Double(people.count) * 0.5)).map { $0 }
            }

            if peopleFilters.fromMyChurches {
                // Filter to people from followed churches
                people = people.filter { person in
                    person.homeChurchName != nil || person.denomination != nil
                }
            }

            if peopleFilters.sharedDenomination {
                // Filter by same denomination as current user
                if let userDenom = appState.profile?.denomination, !userDenom.isEmpty {
                    people = people.filter { $0.denomination == userDenom }
                }
            }

            if peopleFilters.newMembers {
                // Filter to newly joined members (simplified)
                people = people.suffix(Int(Double(people.count) * 0.3)).map { $0 }
            }

            if peopleFilters.faithLeaders {
                // Filter to faith leaders (simplified: people with home church)
                people = people.filter { $0.homeChurchName != nil }
            }

            if peopleFilters.mutualConnections {
                // Filter to people with mutual connections (simplified)
                people = people.filter { person in
                    person.homeChurchName != nil
                }
            }

            if peopleFilters.hasHomeChurch {
                // Filter to people with home church listed
                people = people.filter { $0.homeChurchName != nil }
            }
        }

        return people
    }

    // MARK: - Search Helper
    private func performSearch(_ query: String) {
        let lowercaseQuery = query.lowercased()

        // Search churches with ordering: exact matches first, then related, then location
        var orderedChurches: [Church] = []

        // Exact matches
        orderedChurches += vm.browseChurches.filter { $0.name.lowercased().contains(lowercaseQuery) }

        // Related matches (denomination)
        orderedChurches += vm.browseChurches.filter { church in
            !church.name.lowercased().contains(lowercaseQuery) &&
            church.denomination.lowercased().contains(lowercaseQuery)
        }

        // Location/other matches
        orderedChurches += vm.browseChurches.filter { church in
            !church.name.lowercased().contains(lowercaseQuery) &&
            !church.denomination.lowercased().contains(lowercaseQuery) &&
            church.city.lowercased().contains(lowercaseQuery)
        }

        // Remove duplicates while preserving order
        var seen = Set<String>()
        searchResultsChurches = orderedChurches.filter { church in
            if seen.contains(church.slug) { return false }
            seen.insert(church.slug)
            return true
        }

        // Search people
        searchResultsPeople = vm.browsePeople.filter { person in
            person.name.lowercased().contains(lowercaseQuery) ||
            (person.homeChurchName?.lowercased().contains(lowercaseQuery) ?? false) ||
            (person.denomination?.lowercased().contains(lowercaseQuery) ?? false) ||
            (person.bio?.lowercased().contains(lowercaseQuery) ?? false)
        }
    }

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

                        TextField("Search churches, people, pastors, cities...", text: $searchQuery)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .submitLabel(.search)
                            .onChange(of: searchQuery) { newValue in
                                // Simple search without debouncing for now
                                if newValue.isEmpty {
                                    searchResultsChurches = []
                                    searchResultsPeople = []
                                } else {
                                    performSearch(newValue)
                                }
                            }

                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                                searchResultsChurches = []
                                searchResultsPeople = []
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
                    if !searchQuery.isEmpty {
                        searchResultsView
                    } else {
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
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Churches Near You")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                        Text(locationEnabled ? "Based on your location" : "Turn on location to find nearby churches")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    }
                    .padding(.horizontal, 20)

                    if locationEnabled && !vm.recentlyAdded.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(vm.recentlyAdded.prefix(6), id: \.slug) { church in
                                NavigationLink(destination: ChurchDetailView(church: church)) {
                                    NearbyChurchCard(
                                        church: church,
                                        distance: Double.random(in: 0.5...10.0),
                                        initialIsFollowing: vm.followedChurchSlugs.contains(church.slug)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    } else if !locationEnabled {
                        Button(action: { locationEnabled = true }) {
                            Text("Enable Location")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color(red: 31/255, green: 60/255, blue: 136/255))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)

                // MARK: - 5. Browse by Denomination Categories
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Browse by Denomination")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                        Text("Explore churches by tradition and worship style")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 14) {
                        ForEach(0..<((denominationCategories.count + 1) / 2), id: \.self) { rowIndex in
                            let leftIndex = rowIndex * 2
                            let rightIndex = leftIndex + 1

                            HStack(spacing: 14) {
                                DenominationCategoryCard(
                                    denomination: denominationCategories[leftIndex],
                                    count: vm.denominationCounts[denominationCategories[leftIndex]] ?? 0,
                                    isSelected: selectedDenomination == denominationCategories[leftIndex]
                                ) {
                                    if selectedDenomination == denominationCategories[leftIndex] {
                                        selectedDenomination = nil
                                    } else {
                                        selectedDenomination = denominationCategories[leftIndex]
                                    }
                                }

                                if rightIndex < denominationCategories.count {
                                    DenominationCategoryCard(
                                        denomination: denominationCategories[rightIndex],
                                        count: vm.denominationCounts[denominationCategories[rightIndex]] ?? 0,
                                        isSelected: selectedDenomination == denominationCategories[rightIndex]
                                    ) {
                                        if selectedDenomination == denominationCategories[rightIndex] {
                                            selectedDenomination = nil
                                        } else {
                                            selectedDenomination = denominationCategories[rightIndex]
                                        }
                                    }
                                } else {
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)

                // MARK: - 6. Browse All Churches Directory
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(selectedDenomination.map { "\($0) Churches" } ?? "Browse All Churches")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if selectedDenomination != nil {
                            Button(action: { selectedDenomination = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)

                    if !filteredBrowseChurches.isEmpty {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                                ForEach(filteredBrowseChurches, id: \.slug) { church in
                                    NavigationLink(destination: ChurchDetailView(church: church)) {
                                        DirectoryChurchCard(
                                            church: church,
                                            initialIsFollowing: vm.followedChurchSlugs.contains(church.slug)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                        }
                    } else if !vm.browseChurches.isEmpty {
                        DiscoverEmptyState(
                            icon: "building.2",
                            title: "No churches match your filters",
                            subtitle: "Try adjusting your filters or denomination selection"
                        )
                        .padding(.vertical, 40)
                    }
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

    // MARK: - Quick Filter Row (Churches)
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

                // More Filters button
                Button(action: { showChurchFilterSheet = true }) {
                    Text("More Filters")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(!churchFilters.isEmpty ? .white : Color(red: 55/255, green: 65/255, blue: 81/255))
                        .frame(height: 38)
                        .padding(.horizontal, 14)
                        .background(!churchFilters.isEmpty ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
                        .border(
                            !churchFilters.isEmpty
                                ? Color(red: 31/255, green: 60/255, blue: 136/255)
                                : Color(red: 229/255, green: 231/255, blue: 235/255),
                            width: 1
                        )
                        .cornerRadius(999)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showChurchFilterSheet) {
            ChurchFilterSheet(selectedFilters: $churchFilters)
                .presentationDetents([.fraction(0.85)])
                .presentationCornerRadius(28)
        }
    }

    // MARK: - People Filter Row
    private var peopleFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(peopleFilterOptions, id: \.self) { filter in
                    Button(action: { selectedPeopleFilter = filter }) {
                        Text(filter)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(selectedPeopleFilter == filter ? .white : Color(red: 55/255, green: 65/255, blue: 81/255))
                            .frame(height: 38)
                            .padding(.horizontal, 14)
                            .background(selectedPeopleFilter == filter ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
                            .border(
                                selectedPeopleFilter == filter
                                    ? Color(red: 31/255, green: 60/255, blue: 136/255)
                                    : Color(red: 229/255, green: 231/255, blue: 235/255),
                                width: 1
                            )
                            .cornerRadius(999)
                    }
                    .buttonStyle(.plain)
                }

                // More Filters button
                Button(action: { showPeopleFilterSheet = true }) {
                    Text("More Filters")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(!peopleFilters.isEmpty ? .white : Color(red: 55/255, green: 65/255, blue: 81/255))
                        .frame(height: 38)
                        .padding(.horizontal, 14)
                        .background(!peopleFilters.isEmpty ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
                        .border(
                            !peopleFilters.isEmpty
                                ? Color(red: 31/255, green: 60/255, blue: 136/255)
                                : Color(red: 229/255, green: 231/255, blue: 235/255),
                            width: 1
                        )
                        .cornerRadius(999)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showPeopleFilterSheet) {
            PeopleFilterSheet(selectedFilters: $peopleFilters)
                .presentationDetents([.fraction(0.85)])
                .presentationCornerRadius(28)
        }
    }

    // MARK: - People Content
    private var peopleContent: some View {
        VStack(spacing: 0) {
            if vm.isCuratedLoading {
                loadingPeopleGrid
            } else {
                // MARK: - 1. People Filter Row
                peopleFilterRow
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - 2. Suggested Worshippers
                        if !vm.suggestedPeople.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Suggested Worshippers")
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)

                                peopleSocialList(Array(vm.suggestedPeople.prefix(6)))
                            }
                        }

                        // MARK: - 3. People From Churches You Follow
                        if !filteredBrowsePeople.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("From Your Churches")
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)

                                peopleSocialList(Array(filteredBrowsePeople.prefix(4)))
                            }
                        }

                        // MARK: - 4. New Members
                        if !filteredBrowsePeople.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("New Members")
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)

                                peopleSocialList(Array(filteredBrowsePeople.suffix(4).prefix(4)))
                            }
                        }

                        // MARK: - 5. Faith Leaders
                        if !vm.suggestedPeople.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Faith Leaders")
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)

                                peopleSocialList(Array(vm.suggestedPeople.suffix(4).prefix(4)))
                            }
                        }

                        if vm.browsePeople.isEmpty && vm.suggestedPeople.isEmpty {
                            DiscoverEmptyState(
                                icon: "person.2",
                                title: "No worshippers found",
                                subtitle: "Check back later"
                            )
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.vertical, 20)
                }
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

    // MARK: - People Social List (1-column)
    private func peopleSocialList(_ people: [DiscoverableUser]) -> some View {
        VStack(spacing: 12) {
            ForEach(people, id: \.id) { person in
                NavigationLink(destination: UserProfileView(userId: person.id)) {
                    PeopleSocialCard(
                        user: person,
                        initialIsFollowing: vm.followedUserIds.contains(person.id.uuidString)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - People Grid (legacy 2-column)
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

    // MARK: - Search Results View
    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // Search tabs
            HStack(spacing: 0) {
                ForEach(["All", "Churches", "People"], id: \.self) { tab in
                    Button(action: { selectedSearchTab = tab }) {
                        Text(tab)
                            .font(.system(size: 14, weight: selectedSearchTab == tab ? .bold : .medium))
                            .foregroundColor(selectedSearchTab == tab ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color(red: 107/255, green: 114/255, blue: 128/255))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)

                    if tab != "People" {
                        Divider()
                    }
                }
            }
            .background(Color.white)

            Divider()

            ScrollView {
                VStack(spacing: 12) {
                    if selectedSearchTab == "All" || selectedSearchTab == "Churches" {
                        // Churches results
                        if !searchResultsChurches.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                if selectedSearchTab == "All" {
                                    Text("Churches")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                        .padding(.horizontal, 20)
                                }

                                VStack(spacing: 12) {
                                    ForEach(searchResultsChurches.prefix(selectedSearchTab == "All" ? 3 : 10), id: \.slug) { church in
                                        NavigationLink(destination: ChurchDetailView(church: church)) {
                                            ChurchSearchResultCard(
                                                church: church,
                                                initialIsFollowing: vm.followedChurchSlugs.contains(church.slug)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    if selectedSearchTab == "All" || selectedSearchTab == "People" {
                        // People results
                        if !searchResultsPeople.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                if selectedSearchTab == "All" {
                                    Text("People")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                        .padding(.horizontal, 20)
                                }

                                VStack(spacing: 12) {
                                    ForEach(searchResultsPeople.prefix(selectedSearchTab == "All" ? 3 : 10), id: \.id) { person in
                                        NavigationLink(destination: UserProfileView(userId: person.id)) {
                                            PeopleSearchResultRow(
                                                user: person,
                                                initialIsFollowing: vm.followedUserIds.contains(person.id.uuidString)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    if searchResultsChurches.isEmpty && searchResultsPeople.isEmpty {
                        DiscoverEmptyState(
                            icon: "magnifyingglass",
                            title: "No results found",
                            subtitle: "Try a different search term"
                        )
                        .padding(.vertical, 40)
                    }
                }
                .padding(.vertical, 20)
            }
        }
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
