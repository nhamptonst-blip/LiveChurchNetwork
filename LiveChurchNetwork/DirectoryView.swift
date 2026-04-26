import SwiftUI
import UIKit
import CoreLocation

struct DirectoryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = DiscoverViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @State private var selectedTab: DiscoverTab = .churches
    @State private var isSearchFocused = false
    @State private var activeSmartFilter: String? = nil
    @State private var activeFilters: Set<String> = []
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
    @State private var nearbyRadius: Double = 10.0
    @State private var nearbySort: String = "Closest"
    @State private var showNearbyMap: Bool = false
    @State private var selectedCollection: ChurchCollection? = nil
    @State private var browseSort: String = "Recommended"
    @State private var viewDensity: String = "Comfortable"
    @State private var isLoadingMore: Bool = false
    @State private var recentSearches: [String] = []

    private let suggestedSearches = [
        "Live Churches",
        "Bible Teaching",
        "Worship Communities",
        "Family Friendly",
        "Spanish Services",
        "Young Adults"
    ]

    private let denominationCategories = [
        "Non-Denominational", "Baptist", "Catholic", "Pentecostal",
        "Methodist", "Lutheran", "Presbyterian", "Orthodox",
        "Anglican", "Evangelical"
    ]

    private let peopleFilterOptions = ["Suggested", "Near Me", "From My Churches", "New Members", "Leaders", "Mutuals"]

    private var locationEnabled: Bool {
        locationManager.authorizationStatus == .authorizedWhenInUse
    }

    // MARK: - Computed Filter Properties
    private var filteredBrowseChurches: [Church] {
        var churches = vm.browseChurches

        // Apply collection filter if selected
        if let collection = selectedCollection {
            churches = applyCollectionFilter(churches, collection: collection)
        }

        // Apply denomination filter if selected
        if let denom = selectedDenomination {
            churches = churches.filter { $0.denomination == denom }
        }

        // Apply ChurchFilters
        if !churchFilters.isEmpty {
            // Filter by denominations
            if !churchFilters.denominations.isEmpty {
                churches = churches.filter { churchFilters.denominations.contains($0.denomination) }
            }

            // Filter by languages
            if !churchFilters.languages.isEmpty {
                churches = churches.filter { church in
                    let churchLangs = church.languages.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    return !churchFilters.languages.intersection(Set(churchLangs)).isEmpty
                }
            }

            // Filter by ministries
            if !churchFilters.ministries.isEmpty {
                churches = churches.filter { church in
                    let churchMins = church.ministries.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    return !churchFilters.ministries.intersection(Set(churchMins)).isEmpty
                }
            }

            // Filter by worship styles
            if !churchFilters.worshipStyles.isEmpty {
                churches = churches.filter { church in
                    let churchStyles = church.worshipStyle.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    return !churchFilters.worshipStyles.intersection(Set(churchStyles)).isEmpty
                }
            }

            // Filter by location "Near Me"
            if churchFilters.location.contains("Near Me") {
                if locationEnabled {
                    churches = churches.filter { isNearby($0) }
                } else {
                    churches = []
                }
            }
        }

        return churches
    }

    private var filteredBrowsePeople: [DiscoverableUser] {
        var people = vm.browsePeople.filter { $0.isDiscoverable }

        // Apply PeopleFilters
        if !peopleFilters.isEmpty {
            if peopleFilters.nearMe {
                if locationEnabled {
                    people = people.filter { isPersonNearby($0) }
                } else {
                    people = []
                }
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
                // Filter to faith leaders (church admins)
                people = people.filter { $0.isLeader }
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

    // MARK: - Recent Searches
    private func loadRecentSearches() {
        if let saved = UserDefaults.standard.array(forKey: "recentSearches") as? [String] {
            recentSearches = saved
        }
    }

    private func saveRecentSearch(_ query: String) {
        var searches = recentSearches
        searches.removeAll { $0 == query }
        searches.insert(query, at: 0)
        if searches.count > 5 {
            searches = Array(searches.prefix(5))
        }
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: "recentSearches")
    }

    private func clearAllRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "recentSearches")
    }

    // MARK: - Search Helper
    private func performSearch(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResultsChurches = []
            searchResultsPeople = []
            return
        }

        saveRecentSearch(query)

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

        // Search people (respect isSearchable privacy)
        searchResultsPeople = vm.browsePeople.filter { person in
            person.isSearchable && (
                person.name.lowercased().contains(lowercaseQuery) ||
                (person.homeChurchName?.lowercased().contains(lowercaseQuery) ?? false) ||
                (person.denomination?.lowercased().contains(lowercaseQuery) ?? false) ||
                (person.bio?.lowercased().contains(lowercaseQuery) ?? false)
            )
        }
    }

    enum DiscoverTab {
        case churches
        case people
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.lcCream.ignoresSafeArea()

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
                    .background(Color.lcCream)

                    // MARK: - Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                        TextField("Search churches, people, pastors...", text: $searchQuery, onEditingChanged: { editing in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSearchFocused = editing
                            }
                        })
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .submitLabel(.search)
                            .onChange(of: searchQuery) { newValue in
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
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSearchFocused ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
                    )
                    .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(isSearchFocused ? 0.12 : 0.06), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.bottom, isSearchFocused && searchQuery.isEmpty ? 0 : 16)

                    // MARK: - Tab Switcher (Segmented)
                    if isSearchFocused && searchQuery.isEmpty {
                        // No tab switcher during focused search with empty query
                        EmptyView()
                    } else if !searchQuery.isEmpty {
                        // Search results tabs
                        Picker("Search Results Tab", selection: $selectedSearchTab) {
                            Text("All").tag("All")
                            Text("Churches").tag("Churches")
                            Text("People").tag("People")
                        }
                        .pickerStyle(.segmented)
                        .frame(height: 38)
                        .background(Color(red: 243/255, green: 244/255, blue: 246/255))
                        .cornerRadius(14)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .onChange(of: selectedSearchTab) { _ in
                            HapticEngine.selection()
                        }
                    } else {
                        // Main content tabs (Churches/People)
                        Picker("Main Tab", selection: $selectedTab) {
                            Text("Churches").tag(DiscoverTab.churches)
                            Text("People").tag(DiscoverTab.people)
                        }
                        .pickerStyle(.segmented)
                        .frame(height: 38)
                        .background(Color(red: 243/255, green: 244/255, blue: 246/255))
                        .cornerRadius(14)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .onChange(of: selectedTab) { _ in
                            HapticEngine.selection()
                        }
                    }

                    // MARK: - Content
                    if !searchQuery.isEmpty {
                        searchResultsView
                    } else if isSearchFocused && searchQuery.isEmpty {
                        searchFocusedView
                    } else {
                        ScrollView {
                            if selectedTab == .churches {
                                churchesContent
                            } else {
                                peopleContent
                            }
                        }
                        .background(Color.lcCream)
                        .refreshable {
                            HapticEngine.impact(.light)
                            await vm.reload(appState: appState)
                            HapticEngine.notification(.success)
                        }
                    }
                }
            }
        }
        .task {
            await vm.loadInitialData(appState: appState)
            loadRecentSearches()
        }
    }

    // MARK: - Search Focused View (Recent + Suggested)
    private var searchFocusedView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Discover Shortcuts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Discover")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                        .padding(.horizontal, 20)

                    HStack(spacing: 8) {
                        Button(action: {
                            activeSmartFilter = "Live"
                            isSearchFocused = false
                            HapticEngine.selection()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Live Now")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 999))
                        }

                        Button(action: {
                            activeSmartFilter = "Near"
                            isSearchFocused = false
                            HapticEngine.selection()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Near Me")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 999))
                        }

                        Button(action: {
                            activeSmartFilter = "Trending"
                            isSearchFocused = false
                            HapticEngine.selection()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Trending")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 999))
                        }

                        Button(action: {
                            activeSmartFilter = "Spanish"
                            isSearchFocused = false
                            HapticEngine.selection()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "globe")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Spanish")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 999))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }

                // Recent Searches
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recent")
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                            Spacer()
                            Button(action: {
                                clearAllRecentSearches()
                                HapticEngine.selection()
                            }) {
                                Text("Clear All")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                            }
                        }
                        .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            ForEach(recentSearches.indices, id: \.self) { index in
                                Button(action: {
                                    searchQuery = recentSearches[index]
                                    performSearch(recentSearches[index])
                                    HapticEngine.selection()
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                                        Text(recentSearches[index])
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                                        Spacer()

                                        Image(systemName: "arrow.up.left")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                }

                                if index < recentSearches.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20)
                    }
                }

                // Suggested Searches
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                        .padding(.horizontal, 20)

                    VStack(spacing: 0) {
                        ForEach(suggestedSearches.indices, id: \.self) { index in
                            Button(action: {
                                searchQuery = suggestedSearches[index]
                                performSearch(suggestedSearches[index])
                                HapticEngine.selection()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                                    Text(suggestedSearches[index])
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                                    Spacer()

                                    Image(systemName: "arrow.up.left")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                            }

                            if index < suggestedSearches.count - 1 {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                }

                Spacer()
                    .frame(height: 40)
            }
            .padding(.vertical, 16)
        }
        .background(Color.lcCream)
    }

    // MARK: - Churches Content
    private var churchesContent: some View {
        VStack(spacing: 0) {
            if vm.loadError {
                DiscoverErrorState {
                    Task { await vm.reload(appState: appState) }
                }
            } else if vm.isCuratedLoading {
                loadingGrid
            } else {
                // MARK: - 1. Smart Filter Row
                // Simple filter buttons
                HStack(spacing: 8) {
                    Button(action: {
                        activeSmartFilter = activeSmartFilter == "Live" ? nil : "Live"
                        HapticEngine.selection()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Live")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(activeSmartFilter == "Live" ? .white : Color(red: 55/255, green: 65/255, blue: 81/255))
                        .background(activeSmartFilter == "Live" ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 999))
                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1))
                    }

                    Button(action: {
                        activeSmartFilter = activeSmartFilter == "Nearby" ? nil : "Nearby"
                        HapticEngine.selection()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Nearby")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(activeSmartFilter == "Nearby" ? .white : Color(red: 55/255, green: 65/255, blue: 81/255))
                        .background(activeSmartFilter == "Nearby" ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 999))
                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1))
                    }

                    Button(action: {
                        activeSmartFilter = activeSmartFilter == "Trending" ? nil : "Trending"
                        HapticEngine.selection()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Trending")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(activeSmartFilter == "Trending" ? .white : Color(red: 55/255, green: 65/255, blue: 81/255))
                        .background(activeSmartFilter == "Trending" ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 999))
                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1))
                    }

                    Button(action: {
                        showChurchFilterSheet = true
                        HapticEngine.selection()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Filters")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(!churchFilters.isEmpty ? .white : Color(red: 55/255, green: 65/255, blue: 81/255))
                        .background(!churchFilters.isEmpty ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 999))
                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1))
                    }
                }
                .frame(height: 38)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 12)
                .sheet(isPresented: $showChurchFilterSheet) {
                    ChurchFilterSheet(selectedFilters: $churchFilters)
                        .presentationDetents([.fraction(0.85)])
                        .presentationCornerRadius(28)
                }

                // MARK: - 2. Live Now
                if !vm.liveNowChurches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Live Now")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(vm.liveNowChurches.prefix(8), id: \.slug) { church in
                                    LiveStoryItem(
                                        church: church,
                                        onTap: {
                                            if !church.livestreamUrl.isEmpty {
                                                if let url = URL(string: church.livestreamUrl) {
                                                    UIApplication.shared.open(url)
                                                }
                                            } else {
                                                // Navigate to church profile if no livestream URL
                                                // This would be handled by the parent view routing
                                            }
                                        }
                                    )
                                }
                                Spacer()
                                    .frame(width: 0)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                } else {
                    VStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                            Text("No churches are live right now")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                            Text("Explore featured churches or check back during service times.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
                        )
                        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 12, x: 0, y: 2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }

                // MARK: - 4. Recommended For You (Premium Horizontal Scroll)
                if !vm.trendingChurches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recommended For You")
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

                // MARK: - 5. Churches Near You (Premium Location Experience)
                if locationEnabled {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Churches Near You")
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                            Text("Find communities in your area")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                        }
                        .padding(.horizontal, 20)

                        NearbyControls(
                            selectedRadius: $nearbyRadius,
                            selectedSort: $nearbySort,
                            showFilterSheet: .constant(false)
                        )

                        NearbyViewToggle(showMap: $showNearbyMap)

                        let filteredNearby = filterNearbyByRadius(vm.browseChurches, radius: nearbyRadius)
                        let sortedNearby = sortNearbyChurches(filteredNearby, by: nearbySort)

                        if !sortedNearby.isEmpty {
                            if !showNearbyMap {
                                VStack(spacing: 12) {
                                    let groupedResults = groupNearbyResults(sortedNearby)
                                    ForEach(0..<groupedResults.count, id: \.self) { groupIndex in
                                        VStack(spacing: 12) {
                                            ForEach(groupedResults[groupIndex], id: \.slug) { church in
                                                NavigationLink(destination: ChurchDetailView(church: church)) {
                                                    NearbyChurchCard(
                                                        church: church,
                                                        distance: calculateActualDistance(church),
                                                        initialIsFollowing: vm.followedChurchSlugs.contains(church.slug)
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }

                                        if groupIndex < groupedResults.count - 1 && groupIndex == 0 && nearbyRadius < 50 {
                                            ExpandRadiusPrompt(onExpand: {
                                                nearbyRadius = min(nearbyRadius + 10, 50)
                                            })
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            } else {
                                Text("Map view coming soon")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .background(Color(red: 243/255, green: 244/255, blue: 246/255))
                                    .clipShape(RoundedRectangle(cornerRadius: 22))
                                    .padding(.horizontal, 20)
                            }
                        } else {
                            NearbyEmptyState(
                                onExpandRadius: {
                                    nearbyRadius = min(nearbyRadius + 10, 50)
                                },
                                onBrowseFeatured: {
                                    selectedTab = .churches
                                }
                            )
                        }
                    }
                    .padding(.vertical, 20)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Churches Near You")
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                            Text("Discover nearby communities")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                        }
                        .padding(.horizontal, 20)

                        NearbyPermissionState(onEnable: {
                            locationManager.requestPermission()
                        })
                    }
                    .padding(.vertical, 20)
                }

                // MARK: - 6. Browse by Denomination (Premium Category Discovery)
                DenominationFilterMenu(
                    selectedDenomination: $selectedDenomination,
                    denominationCounts: vm.denominationCounts,
                    denominationCategories: denominationCategories
                )

                // MARK: - 7. Explore Collections (Premium Editorial)
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Explore Collections")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                        Text("Curated ways to find churches you'll love")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    }
                    .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(mockCollections, id: \.id) { collection in
                                CollectionCard(
                                    title: collection.title,
                                    subtitle: collection.subtitle,
                                    icon: collection.icon,
                                    startColor: collection.startColor,
                                    endColor: collection.endColor,
                                    action: {
                                        selectedCollection = collection
                                        selectedDenomination = nil
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 32)

                // MARK: - 8. Browse All Churches Directory (Premium Discovery Engine)
                VStack(alignment: .leading, spacing: 0) {
                    // Header with filter state
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(selectedCollection?.title ?? (selectedDenomination.map { "\($0) Churches" } ?? "Browse All Churches"))
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                            Text("Discover communities across denominations, locations, and worship styles")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                .lineLimit(2)

                            if selectedCollection != nil || selectedDenomination != nil {
                                HStack(spacing: 8) {
                                    Text("Showing: \(selectedCollection?.title ?? selectedDenomination ?? "")")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                                        .padding(.horizontal, 12)
                                        .frame(height: 28)
                                        .background(Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 999))

                                    Spacer()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if selectedCollection != nil || selectedDenomination != nil {
                            Button(action: {
                                selectedCollection = nil
                                selectedDenomination = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)

                    // Control Bar
                    DirectoryControlBar(
                        selectedSort: $browseSort,
                        viewDensity: $viewDensity,
                        onFiltersTap: {
                            showChurchFilterSheet = true
                        },
                        sortOptions: ["Recommended", "Most Followed", "Recently Added", "A–Z", "Live Now"]
                    )

                    // Result Count
                    let sortedChurches = sortBrowseChurches(filteredBrowseChurches, by: browseSort)
                    Text("\(sortedChurches.count) \(selectedDenomination.map { "\($0) " } ?? "")Churches")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                    // Directory Grid
                    if !sortedChurches.isEmpty {
                        ScrollView {
                            let gridColumns = viewDensity == "Comfortable"
                                ? [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
                                : [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

                            LazyVGrid(columns: gridColumns, spacing: viewDensity == "Comfortable" ? 18 : 14) {
                                ForEach(sortedChurches, id: \.slug) { church in
                                    NavigationLink(destination: ChurchDetailView(church: church)) {
                                        DirectoryChurchCard(
                                            church: church,
                                            initialIsFollowing: vm.followedChurchSlugs.contains(church.slug)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }

                                // Load More trigger
                                if vm.hasMoreChurches {
                                    VStack {
                                        ProgressView()
                                    }
                                    .frame(height: 100)
                                    .onAppear {
                                        if !isLoadingMore {
                                            isLoadingMore = true
                                            Task {
                                                await vm.loadMoreChurches()
                                                isLoadingMore = false
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)

                            // Load More Button
                            if vm.hasMoreChurches && !isLoadingMore {
                                Button(action: {
                                    isLoadingMore = true
                                    Task {
                                        await vm.loadMoreChurches()
                                        isLoadingMore = false
                                    }
                                }) {
                                    Text("Load More Churches")
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 42)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 999))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 999)
                                                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                        }
                    } else if !vm.browseChurches.isEmpty {
                        // No results for current filters
                        VStack(alignment: .center, spacing: 16) {
                            Image(systemName: "building.2.circle.fill")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                            VStack(alignment: .center, spacing: 8) {
                                Text("No churches found")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                                Text("Try adjusting filters or exploring another denomination or city.")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                    .multilineTextAlignment(.center)
                            }

                            HStack(spacing: 12) {
                                Button(action: {
                                    churchFilters = ChurchFilters()
                                    selectedDenomination = nil
                                    selectedCollection = nil
                                }) {
                                    Text("Clear Filters")
                                        .font(.system(size: 13, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .foregroundColor(.white)
                                        .background(Color(red: 31/255, green: 60/255, blue: 136/255))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }

                                Button(action: {
                                    selectedCollection = nil
                                    selectedDenomination = nil
                                }) {
                                    Text("Browse Featured")
                                        .font(.system(size: 13, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(22)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
                        )
                        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 12, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 40)
                    }
                }
                .padding(.vertical, 32)

                if vm.browseChurches.isEmpty {
                    DiscoverEmptyState(
                        icon: "building.2",
                        title: "No churches found",
                        subtitle: "Try adjusting your search",
                        actions: [
                            .init(label: "Clear Filters") {
                                churchFilters = ChurchFilters()
                                selectedDenomination = nil
                                selectedCollection = nil
                            }
                        ]
                    )
                    .padding(.vertical, 40)
                }
            }
        }
    }

    // MARK: - Proximity Helpers
    private func isNearby(_ church: Church) -> Bool {
        if let userLoc = locationManager.userLocation,
           let lat = church.latitude, let lng = church.longitude {
            return userLoc.distance(from: CLLocation(latitude: lat, longitude: lng)) < 80_000 // 50 miles
        }
        // Fall back to city string match
        if let userCity = locationManager.userCity {
            return church.city.lowercased().contains(userCity.lowercased())
        }
        return false
    }

    private func isPersonNearby(_ person: DiscoverableUser) -> Bool {
        guard let userCity = locationManager.userCity,
              let personCity = person.city else { return false }
        return personCity.lowercased().contains(userCity.lowercased())
    }

    // MARK: - Browse Directory Sorting Helper
    private func sortBrowseChurches(_ churches: [Church], by sortOption: String) -> [Church] {
        switch sortOption {
        case "Recommended":
            return churches.sorted { c1, c2 in
                let s1 = (c1.isLive ? 3 : 0) + (c1.isVerified ? 2 : 0) + (c1.isTrending ? 1 : 0)
                let s2 = (c2.isLive ? 3 : 0) + (c2.isVerified ? 2 : 0) + (c2.isTrending ? 1 : 0)
                if s1 != s2 { return s1 > s2 }
                return c1.followerCount > c2.followerCount
            }
        case "Most Followed":
            return churches.sorted { $0.followerCount > $1.followerCount }
        case "Recently Added":
            return churches
        case "A–Z":
            return churches.sorted { $0.name < $1.name }
        case "Live Now":
            return churches.sorted { c1, c2 in
                if c1.isLive != c2.isLive { return c1.isLive }
                return c1.followerCount > c2.followerCount
            }
        default:
            return churches
        }
    }

    // MARK: - Collection Filtering Helper
    private func applyCollectionFilter(_ churches: [Church], collection: ChurchCollection) -> [Church] {
        switch collection.filterType {
        case .live:
            return churches.filter { $0.isLive }
        case .city:
            if let city = collection.filterValue {
                return churches.filter { $0.city.lowercased().contains(city.lowercased()) }
            }
            return churches
        case .trending:
            return churches.filter { $0.isTrending }
        case .worship:
            return churches.filter { church in
                !church.worshipStyle.isEmpty || !church.ministries.isEmpty
            }
        case .new:
            return churches.filter { $0.isNew }
        case .bibleteaching:
            return churches.filter { church in
                church.ministries.lowercased().contains("bible") || church.ministries.lowercased().contains("study")
            }
        case .familyfriendly:
            return churches.filter { church in
                church.ministries.lowercased().contains("families") || church.ministries.lowercased().contains("family")
            }
        case .spanish:
            return churches.filter { church in
                church.languages.lowercased().contains("spanish")
            }
        }
    }

    // MARK: - Nearby Churches Helpers
    private func calculateActualDistance(_ church: Church) -> Double? {
        guard let userLoc = locationManager.userLocation,
              let lat = church.latitude,
              let lng = church.longitude else {
            return nil
        }
        let churchLoc = CLLocation(latitude: lat, longitude: lng)
        let distanceMeters = userLoc.distance(from: churchLoc)
        return distanceMeters / 1609.34 // Convert to miles
    }

    private func filterNearbyByRadius(_ churches: [Church], radius: Double) -> [Church] {
        churches.filter { church in
            if let distance = calculateActualDistance(church) {
                return distance <= radius
            }
            return false
        }
    }

    private func sortNearbyChurches(_ churches: [Church], by sortOption: String) -> [Church] {
        switch sortOption {
        case "Closest":
            return churches.sorted { c1, c2 in
                let d1 = calculateActualDistance(c1) ?? Double.infinity
                let d2 = calculateActualDistance(c2) ?? Double.infinity
                return d1 < d2
            }
        case "Most Followed":
            return churches.sorted { $0.followerCount > $1.followerCount }
        case "Live Now":
            var sorted = churches.sorted { $0.isLive && !$1.isLive }
            if !sorted.allSatisfy({ $0.isLive == sorted.first!.isLive }) {
                sorted = sorted.sorted { c1, c2 in
                    if c1.isLive != c2.isLive {
                        return c1.isLive
                    }
                    return (calculateActualDistance(c1) ?? Double.infinity) < (calculateActualDistance(c2) ?? Double.infinity)
                }
            }
            return sorted
        case "Recommended":
            return churches.sorted { c1, c2 in
                let s1 = (c1.isLive ? 3 : 0) + (c1.isVerified ? 2 : 0) + (c1.isTrending ? 1 : 0)
                let s2 = (c2.isLive ? 3 : 0) + (c2.isVerified ? 2 : 0) + (c2.isTrending ? 1 : 0)
                return s1 > s2
            }
        default:
            return churches
        }
    }

    private func groupNearbyResults(_ churches: [Church]) -> [[Church]] {
        var groups: [[Church]] = []
        var currentGroup: [Church] = []

        for (index, church) in churches.enumerated() {
            currentGroup.append(church)

            if currentGroup.count == 4 || index == churches.count - 1 {
                groups.append(currentGroup)
                currentGroup = []
            }
        }

        return groups
    }

    // MARK: - People Filter Row
    private var peopleFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(peopleFilterOptions, id: \.self) { filter in
                    Button(action: {
                        selectedPeopleFilter = filter
                        HapticEngine.selection()
                    }) {
                        Text(filter)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(selectedPeopleFilter == filter ? .white : Color(red: 55/255, green: 65/255, blue: 81/255))
                            .frame(height: 36)
                            .padding(.horizontal, 14)
                            .background(selectedPeopleFilter == filter ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 999))
                            .overlay(
                                RoundedRectangle(cornerRadius: 999).stroke(
                                    selectedPeopleFilter == filter
                                        ? Color(red: 31/255, green: 60/255, blue: 136/255)
                                        : Color(red: 229/255, green: 231/255, blue: 235/255),
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }

                // More Filters button
                Button(action: {
                    showPeopleFilterSheet = true
                    HapticEngine.selection()
                }) {
                    Text("More Filters")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(!peopleFilters.isEmpty ? .white : Color(red: 55/255, green: 65/255, blue: 81/255))
                        .frame(height: 36)
                        .padding(.horizontal, 14)
                        .background(!peopleFilters.isEmpty ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 999))
                        .overlay(
                            RoundedRectangle(cornerRadius: 999).stroke(
                                !peopleFilters.isEmpty
                                    ? Color(red: 31/255, green: 60/255, blue: 136/255)
                                    : Color(red: 229/255, green: 231/255, blue: 235/255),
                                lineWidth: 1
                            )
                        )
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
            if vm.loadError {
                DiscoverErrorState {
                    Task { await vm.reload(appState: appState) }
                }
            } else if vm.isCuratedLoading {
                loadingPeopleGrid
            } else {
                // MARK: - 0. People Header
                VStack(alignment: .leading, spacing: 2) {
                    Text("Discover People")
                        .font(.system(size: 34, weight: .black))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                    Text("Connect with believers, church communities, and faith leaders")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)

                // MARK: - 1. People Filter Row
                peopleFilterRow
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Show content based on selected filter
                        if selectedPeopleFilter == "Suggested" && !vm.suggestedPeople.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Suggested For You")
                                        .font(.system(size: 22, weight: .black))
                                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                                    Text("High-quality recommendations based on your interests")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                }
                                .padding(.horizontal, 20)

                                peopleSocialListWithMetadata(Array(vm.suggestedPeople.prefix(10)))
                            }
                        } else if selectedPeopleFilter == "Near Me" {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("People Near You")
                                        .font(.system(size: 22, weight: .black))
                                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                                    Text("Connect with believers in your area")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                }
                                .padding(.horizontal, 20)

                                let nearbyPeople = vm.browsePeople.filter { isPersonNearby($0) }
                                if !nearbyPeople.isEmpty {
                                    peopleSocialListWithMetadata(Array(nearbyPeople.prefix(10)))
                                } else {
                                    Text("No people found nearby. Enable location or expand your search radius.")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                        .padding(.horizontal, 20)
                                }
                            }
                        } else if selectedPeopleFilter == "From My Churches" && !filteredBrowsePeople.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("From Churches You Follow")
                                        .font(.system(size: 22, weight: .black))
                                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                                    Text("Meet members from communities you follow")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                }
                                .padding(.horizontal, 20)

                                peopleSocialListWithMetadata(Array(filteredBrowsePeople.prefix(10)))
                            }
                        } else if selectedPeopleFilter == "New Members" && !filteredBrowsePeople.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("New Members")
                                        .font(.system(size: 22, weight: .black))
                                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                                    Text("Welcome fresh voices joining the community")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                }
                                .padding(.horizontal, 20)

                                let newMembers = filteredBrowsePeople.suffix(Int(Double(filteredBrowsePeople.count) * 0.3)).map { $0 }
                                peopleSocialListWithMetadata(Array(newMembers.prefix(10)), markAsNew: true)
                            }
                        } else if selectedPeopleFilter == "Leaders" && !vm.suggestedPeople.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Faith Leaders")
                                        .font(.system(size: 22, weight: .black))
                                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                                    Text("Pastors, ministry leaders, and worship leaders")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                }
                                .padding(.horizontal, 20)

                                peopleSocialListWithMetadata(Array(vm.suggestedPeople.prefix(10)))
                            }
                        } else if selectedPeopleFilter == "Mutuals" && !filteredBrowsePeople.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Mutual Connections")
                                        .font(.system(size: 22, weight: .black))
                                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                                    Text("People you both follow")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                }
                                .padding(.horizontal, 20)

                                peopleSocialListWithMetadata(Array(filteredBrowsePeople.prefix(10)))
                            }
                        }

                        if vm.browsePeople.isEmpty && vm.suggestedPeople.isEmpty {
                            VStack(alignment: .center, spacing: 16) {
                                Image(systemName: "person.2.circle.fill")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                                VStack(alignment: .center, spacing: 8) {
                                    Text("No people to discover yet")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                                    Text("Check back as more members join your faith community.")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                        .multilineTextAlignment(.center)
                                }

                                Button(action: {
                                    selectedTab = .churches
                                }) {
                                    Text("Explore Churches")
                                        .font(.system(size: 13, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .foregroundColor(.white)
                                        .background(Color(red: 31/255, green: 60/255, blue: 136/255))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            .padding(22)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
                            )
                            .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 12, x: 0, y: 2)
                            .padding(.horizontal, 20)
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
                        initialIsFollowing: vm.followedUserIds.contains(person.id.uuidString),
                        isNew: false,
                        socialProof: nil
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    private func peopleSocialListWithMetadata(_ people: [DiscoverableUser], markAsNew: Bool = false) -> some View {
        VStack(spacing: 12) {
            ForEach(people, id: \.id) { person in
                NavigationLink(destination: UserProfileView(userId: person.id)) {
                    PeopleSocialCard(
                        user: person,
                        initialIsFollowing: vm.followedUserIds.contains(person.id.uuidString),
                        isNew: markAsNew,
                        socialProof: nil
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
            // Search tabs (segmented control)
            Picker("Search Results Tab", selection: $selectedSearchTab) {
                Text("All").tag("All")
                Text("Churches").tag("Churches")
                Text("People").tag("People")
            }
            .pickerStyle(.segmented)
            .frame(height: 38)
            .background(Color(red: 243/255, green: 244/255, blue: 246/255))
            .cornerRadius(14)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .onChange(of: selectedSearchTab) { _ in
                HapticEngine.selection()
            }

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    if selectedSearchTab == "All" || selectedSearchTab == "Churches" {
                        // Churches results
                        if !searchResultsChurches.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                if selectedSearchTab == "All" {
                                    Text("Churches")
                                        .font(.system(size: 15, weight: .black))
                                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
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
                            VStack(alignment: .leading, spacing: 12) {
                                if selectedSearchTab == "All" {
                                    Text("People")
                                        .font(.system(size: 15, weight: .black))
                                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
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
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255))

                            VStack(spacing: 8) {
                                Text("No results found")
                                    .font(.system(size: 17, weight: .black))
                                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                                Text("Try searching by church name, city, denomination, pastor, or person.")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                    .multilineTextAlignment(.center)
                            }

                            HStack(spacing: 12) {
                                Button(action: {
                                    searchQuery = ""
                                    searchResultsChurches = []
                                    searchResultsPeople = []
                                    HapticEngine.impact(.light)
                                }) {
                                    Text("Clear Search")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
                                        )
                                }

                                Button(action: {
                                    searchQuery = ""
                                    isSearchFocused = false
                                    HapticEngine.impact(.light)
                                }) {
                                    Text("Browse Churches")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color(red: 31/255, green: 60/255, blue: 136/255))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(22)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
                        )
                        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 12, x: 0, y: 2)
                        .padding(.horizontal, 20)
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
                .font(.system(size: 22, weight: .black))
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
                .font(.system(size: 22, weight: .black))
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    PeopleSocialCardSkeleton()
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
