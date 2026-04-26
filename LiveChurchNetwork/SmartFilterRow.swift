import SwiftUI

struct SmartFilterRow: View {
    @Binding var activeFilter: String?
    @Binding var showFilterSheet: Bool
    var filterCount: Int = 0
    var onFilterChange: (String?) -> Void = { _ in }

    private let filters = [
        ("Live", "play.circle.fill", "Live"),
        ("Nearby", "location.fill", "Nearby"),
        ("Trending", "arrow.up.right", "Trending"),
        ("Filters", "slider.horizontal.3", "Filters")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    let (label, icon, tag) = filters[index]
                    SmartFilterButton(
                        label: label,
                        icon: icon,
                        isActive: activeFilter == tag,
                        action: {
                            if activeFilter == tag {
                                activeFilter = nil
                            } else {
                                activeFilter = tag
                            }
                            onFilterChange(activeFilter)
                            HapticEngine.selection()
                        }
                    )
                }

                // Filters button
                SmartFilterButton(
                    label: "Filters",
                    icon: "slider.horizontal.3",
                    isActive: filterCount > 0,
                    badgeCount: filterCount > 0 ? filterCount : nil,
                    action: {
                        showFilterSheet = true
                        HapticEngine.selection()
                    }
                )
            }
            .frame(height: 38)
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)
        }
        .background(Color(red: 250/255, green: 249/255, blue: 246/255))
    }
}

struct SmartFilterButton: View {
    let label: String
    let icon: String
    let isActive: Bool
    var badgeCount: Int? = nil
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))

                Text(label)
                    .font(.system(size: 13, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isActive ? .white : Color(red: 55/255, green: 65/255, blue: 81/255))
            .background(isActive ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 999))
            .overlay(
                RoundedRectangle(cornerRadius: 999).stroke(
                    isActive
                        ? Color(red: 31/255, green: 60/255, blue: 136/255)
                        : Color(red: 229/255, green: 231/255, blue: 235/255),
                    lineWidth: 1
                )
            )
            .shadow(
                color: isActive
                    ? Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.20)
                    : Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.04),
                radius: isActive ? 6 : 3,
                x: 0,
                y: isActive ? 6 : 3
            )
            .overlay(
                Group {
                    if let count = badgeCount, count > 0 {
                        VStack(alignment: .trailing) {
                            HStack(alignment: .top, spacing: 0) {
                                Spacer()
                                Text("\(count)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 18, height: 18)
                                    .background(Color(red: 239/255, green: 68/255, blue: 68/255))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(4)
                    }
                }
            )
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }
}

#Preview {
    SmartFilterRow(activeFilter: .constant("Live"), showFilterSheet: .constant(false), filterCount: 0)
}
