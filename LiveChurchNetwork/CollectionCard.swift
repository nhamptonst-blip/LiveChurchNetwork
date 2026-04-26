import SwiftUI

struct CollectionCard: View {
    let title: String
    let subtitle: String
    let icon: String?
    let startColor: Color
    let endColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticEngine.impact(.light)
            action()
        }) {
            ZStack(alignment: .topTrailing) {
                // Background gradient with overlay
                LinearGradient(
                    gradient: Gradient(colors: [startColor, endColor]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Color(red: 17/255, green: 24/255, blue: 39/255)
                        .opacity(0.32)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .black))
                        .tracking(-0.2)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.82))
                        .lineLimit(1)

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)

                // Optional icon in top-right
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(16)
                }
            }
            .frame(width: 220, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.10), radius: 12, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Browse \(title)")
        .accessibilityHint(subtitle)
    }
}

// MARK: - Collection Data Structure

struct ChurchCollection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String?
    let startColor: Color
    let endColor: Color
    let filterType: CollectionFilterType
    let filterValue: String?

    enum CollectionFilterType {
        case live
        case city
        case trending
        case worship
        case new
        case bibleteaching
        case familyfriendly
        case spanish
    }
}

// MARK: - Mock Collections

let mockCollections: [ChurchCollection] = [
    ChurchCollection(
        title: "Streaming Live",
        subtitle: "42 churches",
        icon: "play.circle.fill",
        startColor: Color(red: 0.938, green: 0.267, blue: 0.267),
        endColor: Color(red: 0.616, green: 0.105, blue: 0.105),
        filterType: .live,
        filterValue: nil
    ),
    ChurchCollection(
        title: "Churches Near Los Angeles",
        subtitle: "286 churches",
        icon: "location.fill",
        startColor: Color(red: 0.125, green: 0.376, blue: 0.533),
        endColor: Color(red: 0.090, green: 0.251, blue: 0.369),
        filterType: .city,
        filterValue: "Los Angeles"
    ),
    ChurchCollection(
        title: "Growing Communities",
        subtitle: "Popular this week",
        icon: "arrow.up.circle.fill",
        startColor: Color(red: 1.0, green: 0.835, blue: 0.412),
        endColor: Color(red: 0.718, green: 0.482, blue: 0.125),
        filterType: .trending,
        filterValue: nil
    ),
    ChurchCollection(
        title: "Worship-Focused Churches",
        subtitle: "123 churches",
        icon: "music.note.list",
        startColor: Color(red: 0.488, green: 0.227, blue: 0.929),
        endColor: Color(red: 0.188, green: 0.176, blue: 0.506),
        filterType: .worship,
        filterValue: nil
    ),
    ChurchCollection(
        title: "New This Week",
        subtitle: "Join new communities",
        icon: "sparkles",
        startColor: Color(red: 0.974, green: 0.663, blue: 0.411),
        endColor: Color(red: 0.804, green: 0.494, blue: 0.165),
        filterType: .new,
        filterValue: nil
    ),
    ChurchCollection(
        title: "Bible Teaching Churches",
        subtitle: "94 churches",
        icon: "book.fill",
        startColor: Color(red: 0.258, green: 0.373, blue: 0.529),
        endColor: Color(red: 0.145, green: 0.212, blue: 0.302),
        filterType: .bibleteaching,
        filterValue: nil
    ),
    ChurchCollection(
        title: "Family Friendly Churches",
        subtitle: "167 churches",
        icon: "person.3.fill",
        startColor: Color(red: 0.2, green: 0.5, blue: 0.4),
        endColor: Color(red: 0.1, green: 0.35, blue: 0.25),
        filterType: .familyfriendly,
        filterValue: nil
    ),
    ChurchCollection(
        title: "Spanish-Speaking Churches",
        subtitle: "89 churches",
        icon: "globe",
        startColor: Color(red: 0.639, green: 0.239, blue: 0.318),
        endColor: Color(red: 0.427, green: 0.118, blue: 0.157),
        filterType: .spanish,
        filterValue: nil
    )
]

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
            ForEach(mockCollections.prefix(4), id: \.id) { collection in
                CollectionCard(
                    title: collection.title,
                    subtitle: collection.subtitle,
                    icon: collection.icon,
                    startColor: collection.startColor,
                    endColor: collection.endColor,
                    action: { }
                )
            }
        }
        .padding(.horizontal, 20)
    }
    .background(Color(red: 250/255, green: 249/255, blue: 246/255))
}
