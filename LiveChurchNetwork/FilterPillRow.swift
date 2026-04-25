import SwiftUI

struct FilterPillRow: View {
    @Binding var activeFilters: Set<DiscoverViewModel.DiscoverFilter>
    @State private var showFilterDrawer = false

    private let denominationOptions = [
        "Non-Denominational", "Baptist", "Catholic", "Pentecostal"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Top row: Quick filters (non-scrolling)
            HStack(spacing: 8) {
                // Live Now
                FilterChip(
                    label: "Live Now",
                    isActive: activeFilters.contains(.liveNow),
                    showBadge: true,
                    badgeColor: Color(red: 239/255, green: 68/255, blue: 68/255)
                ) {
                    toggleFilter(.liveNow)
                }

                // Near Me
                FilterChip(
                    label: "Near Me",
                    isActive: activeFilters.contains(.nearMe),
                    showBadge: false
                ) {
                    toggleFilter(.nearMe)
                }

                // Trending
                FilterChip(
                    label: "Trending",
                    isActive: activeFilters.contains(.trending),
                    showBadge: false
                ) {
                    toggleFilter(.trending)
                }

                // More Filters (right side)
                Spacer()
                FilterChip(
                    label: "More",
                    isActive: false,
                    showBadge: false,
                    isAction: true
                ) {
                    showFilterDrawer = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // Scrollable denomination chips (if needed)
            if !denominationOptions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(denominationOptions, id: \.self) { denom in
                            FilterChip(
                                label: denom,
                                isActive: activeFilters.contains(.denomination(denom)),
                                showBadge: false
                            ) {
                                toggleFilter(.denomination(denom))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showFilterDrawer) {
            FilterDrawerView(activeFilters: $activeFilters)
                .presentationDetents([.fraction(0.85)])
                .presentationDragIndicator(.visible)
        }
    }

    private func toggleFilter(_ filter: DiscoverViewModel.DiscoverFilter) {
        if activeFilters.contains(filter) {
            activeFilters.remove(filter)
        } else {
            activeFilters.insert(filter)
        }
    }
}

struct FilterChip: View {
    let label: String
    let isActive: Bool
    let showBadge: Bool
    let badgeColor: Color
    var isAction: Bool = false
    let action: () -> Void

    init(label: String, isActive: Bool, showBadge: Bool = false, badgeColor: Color = .clear, isAction: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.isActive = isActive
        self.showBadge = showBadge
        self.badgeColor = badgeColor
        self.isAction = isAction
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))

                if showBadge && isActive {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isActive ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
            .foregroundColor(isActive ? .white : Color(red: 55/255, green: 65/255, blue: 81/255))
            .border(
                isActive ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color(red: 229/255, green: 231/255, blue: 235/255),
                width: 1
            )
            .cornerRadius(999)
        }
    }
}

#Preview {
    @State var filters: Set<DiscoverViewModel.DiscoverFilter> = []
    return FilterPillRow(activeFilters: $filters)
}
