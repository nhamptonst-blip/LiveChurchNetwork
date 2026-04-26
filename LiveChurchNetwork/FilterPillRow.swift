import SwiftUI

struct FilterPillRow: View {
    @Binding var activeFilters: Set<DiscoverViewModel.DiscoverFilter>
    var vm: DiscoverViewModel
    @State private var showFilterDrawer = false

    private let denominationOptions = [
        "Non-Denominational", "Baptist", "Catholic", "Pentecostal"
    ]

    var body: some View {
        VStack(spacing: 12) {
            // First row: Quick filters
            HStack(spacing: 10) {
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
            }

            // Second row: More filters button
            HStack {
                FilterChip(
                    label: "More Filters",
                    isActive: false,
                    showBadge: false,
                    isAction: true
                ) {
                    showFilterDrawer = true
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .sheet(isPresented: $showFilterDrawer) {
            FilterDrawerView(activeFilters: $activeFilters, vm: vm)
                .presentationDetents([.fraction(0.85)])
                .presentationDragIndicator(.visible)
        }
    }

    private func toggleFilter(_ filter: DiscoverViewModel.DiscoverFilter) {
        HapticEngine.selection()
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
                // Icon based on filter type
                if showBadge {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                } else if label == "Near Me" {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .semibold))
                } else if label == "Trending" {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                } else if label == "More" {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12, weight: .semibold))
                }

                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.2)
                    .lineLimit(1)

                if showBadge && isActive {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 32)
            .background(
                isActive
                    ? Color(red: 31/255, green: 60/255, blue: 136/255)
                    : Color.white
            )
            .foregroundColor(isActive ? .white : Color(red: 31/255, green: 60/255, blue: 136/255))
            .clipShape(RoundedRectangle(cornerRadius: 999))
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(
                        isActive
                            ? Color.clear
                            : Color(red: 229/255, green: 231/255, blue: 235/255),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isActive ? Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.12) : Color.clear,
                radius: isActive ? 4 : 0,
                x: 0,
                y: isActive ? 2 : 0
            )
        }
    }
}

#Preview {
    FilterPillRow(activeFilters: .constant(Set()), vm: DiscoverViewModel())
}
