import SwiftUI

// MARK: - Shimmer Modifier

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.6 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating.toggle()
                }
            }
    }
}

// MARK: - Discover Search Bar

struct DiscoverSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.lcText3)

            TextField("Search...", text: $text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.lcText)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.lcText3)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Discover Filter Chips

struct DiscoverFilterChips: View {
    @Binding var selectedDenomination: String
    @Binding var showLiveOnly: Bool
    let liveCount: Int

    private let denominations = [
        "Non-Denominational",
        "Baptist",
        "Catholic",
        "Spanish/Hispanic",
        "Online Only"
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Live Now toggle
                Button {
                    showLiveOnly.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "dot.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Live Now")
                            .font(.system(size: 13, weight: .semibold))
                        if liveCount > 0 {
                            Text("\(liveCount)")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.leading, 4)
                        }
                    }
                    .foregroundColor(showLiveOnly ? .white : .lcText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(showLiveOnly ? Color.lcNavy : Color.white)
                    .cornerRadius(20)
                    .shadow(color: showLiveOnly ? Color.lcNavy.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
                }

                // Denomination chips
                ForEach(denominations, id: \.self) { denom in
                    Button {
                        selectedDenomination = selectedDenomination == denom ? "All" : denom
                    } label: {
                        Text(denom)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedDenomination == denom ? .white : .lcText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedDenomination == denom ? Color.lcNavy : Color.white)
                            .cornerRadius(20)
                            .shadow(color: selectedDenomination == denom ? Color.lcNavy.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.97))
    }
}

// MARK: - Discover Empty State

struct DiscoverEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.lcText3)

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.lcText)

            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Church Discovery Card Skeleton

struct ChurchDiscoveryCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.lcBorder.opacity(0.5))
                .frame(height: 120)

            ZStack {
                Color.clear.frame(height: 28)
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.lcBorder.opacity(0.5))
                        .frame(width: 50, height: 50)
                    Spacer()
                }
                .frame(height: 50)
            }
            .frame(height: 50)

            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.lcBorder.opacity(0.5))
                    .frame(height: 12)
                    .frame(maxWidth: 100)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.lcBorder.opacity(0.5))
                    .frame(height: 10)
                    .frame(maxWidth: 70)

                Spacer()

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.lcBorder.opacity(0.5))
                    .frame(height: 32)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(height: 62)
        }
        .frame(height: 240)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        .opacity(isAnimating ? 0.6 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Discover Section Header

struct DiscoverSectionHeader: View {
    let title: String
    let seeAllAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.lcText)

            Spacer()

            if seeAllAction != nil {
                Button {
                    seeAllAction?()
                } label: {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcNavy)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.lcNavy)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Horizontal Carousel

struct HorizontalCarousel<Content: View>: View {
    let content: () -> Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                content()
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 240)
    }
}

// MARK: - Church List Row (for list view mode)

struct ChurchListRow: View {
    let church: Church
    let isFollowing: Bool
    let onFollowToggle: () -> Void

    private var defaultColor: Color {
        let hash = church.denomination.hashValue % 5
        switch hash {
        case 0: return Color(red: 0.2, green: 0.4, blue: 0.8)
        case 1: return Color(red: 0.8, green: 0.3, blue: 0.3)
        case 2: return Color(red: 0.3, green: 0.6, blue: 0.4)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return Color(red: 0.6, green: 0.3, blue: 0.7)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Avatar — 64x64
            ZStack {
                Circle()
                    .fill(defaultColor)
                    .frame(width: 64, height: 64)

                if !church.image.isEmpty, let url = URL(string: church.image) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        default:
                            Text(church.name.prefix(1).uppercased())
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    Text(church.name.prefix(1).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Name/Denom/City — VStack
            VStack(alignment: .leading, spacing: 3) {
                Text(church.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lcText)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(church.denomination)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.lcText3)
                        .lineLimit(1)

                    if church.isLive {
                        HStack(spacing: 2) {
                            Image(systemName: "dot.circle.fill")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(.red)
                            Text("Live")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                }

                if !church.phone.isEmpty {
                    Text(church.phone)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.lcText3)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Follow button (small)
            Button {
                onFollowToggle()
            } label: {
                Text(isFollowing ? "✓" : "+")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isFollowing ? .lcNavy : .white)
                    .frame(width: 28, height: 28)
                    .background(isFollowing ? Color.clear : Color.lcNavy)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.lcNavy, lineWidth: isFollowing ? 1.5 : 0)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Church Grid Card (compact for grid view)

struct ChurchGridCard: View {
    let church: Church
    let isFollowing: Bool
    let onFollowToggle: () -> Void

    private var defaultGradient: LinearGradient {
        let hash = church.denomination.hashValue % 5
        let colors: (top: Color, bottom: Color) = {
            switch hash {
            case 0: return (Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.1, green: 0.3, blue: 0.7))
            case 1: return (Color(red: 0.8, green: 0.3, blue: 0.3), Color(red: 0.7, green: 0.2, blue: 0.2))
            case 2: return (Color(red: 0.3, green: 0.6, blue: 0.4), Color(red: 0.2, green: 0.5, blue: 0.3))
            case 3: return (Color(red: 0.8, green: 0.5, blue: 0.2), Color(red: 0.7, green: 0.4, blue: 0.1))
            default: return (Color(red: 0.6, green: 0.3, blue: 0.7), Color(red: 0.5, green: 0.2, blue: 0.6))
            }
        }()
        return LinearGradient(gradient: Gradient(colors: [colors.top, colors.bottom]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Image area — 90pt
            ZStack(alignment: .topTrailing) {
                if !church.image.isEmpty, let url = URL(string: church.image) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .clipped()
                        default:
                            defaultGradient
                        }
                    }
                } else {
                    defaultGradient
                }

                // Live badge
                if church.isLive {
                    HStack(spacing: 4) {
                        Image(systemName: "dot.circle.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("Live")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.9, green: 0.2, blue: 0.2))
                    .cornerRadius(8)
                    .padding(8)
                }
            }
            .frame(height: 90)
            .clipped()

            // Content area
            VStack(spacing: 6) {
                Text(church.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.lcText)
                    .lineLimit(1)

                Text(church.denomination)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.lcText3)
                    .lineLimit(1)

                if !church.phone.isEmpty {
                    Text(church.phone)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.lcText3)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    onFollowToggle()
                } label: {
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isFollowing ? .lcNavy : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(isFollowing ? Color.clear : Color.lcNavy)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.lcNavy, lineWidth: isFollowing ? 1 : 0)
                        )
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .frame(maxHeight: .infinity)
        }
        .frame(height: 200)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Person Grid Card (simplified, no cover image)

struct PersonGridCard: View {
    let user: DiscoverableUser
    let isFollowing: Bool
    let onFollowToggle: () -> Void

    private var defaultColor: Color {
        let hash = (user.denomination ?? "").hashValue % 5
        switch hash {
        case 0: return Color(red: 0.2, green: 0.4, blue: 0.8)
        case 1: return Color(red: 0.8, green: 0.3, blue: 0.3)
        case 2: return Color(red: 0.3, green: 0.6, blue: 0.4)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return Color(red: 0.6, green: 0.3, blue: 0.7)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Avatar — 56pt
            ZStack {
                Circle()
                    .fill(defaultColor)
                    .frame(width: 56, height: 56)

                if let photoUrl = user.photoUrl, !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(Circle())
                        default:
                            Text(user.name.prefix(1).uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    Text(user.name.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Name
            Text(user.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.lcText)
                .lineLimit(1)
                .multilineTextAlignment(.center)

            // Denomination badge
            if let denom = user.denomination {
                Text(denom)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.lcText3)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.lcBorder.opacity(0.5))
                    .cornerRadius(6)
            }

            // City
            if let city = user.city {
                Text(city)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.lcText3)
                    .lineLimit(1)
            }

            Spacer()

            // Follow button
            Button {
                onFollowToggle()
            } label: {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isFollowing ? .lcNavy : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(isFollowing ? Color.clear : Color.lcNavy)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.lcNavy, lineWidth: isFollowing ? 1 : 0)
                    )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(height: 170)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - People Discovery Card Skeleton

struct PeopleDiscoveryCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.lcBorder.opacity(0.5))
                .frame(height: 100)

            ZStack {
                Color.clear.frame(height: 30)
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.lcBorder.opacity(0.5))
                        .frame(width: 60, height: 60)
                    Spacer()
                }
                .frame(height: 60)
            }
            .frame(height: 60)

            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.lcBorder.opacity(0.5))
                    .frame(height: 12)
                    .frame(maxWidth: 120)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.lcBorder.opacity(0.5))
                    .frame(height: 10)
                    .frame(maxWidth: 80)

                Spacer()

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.lcBorder.opacity(0.5))
                    .frame(height: 32)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(height: 90)
        }
        .frame(height: 250)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        .opacity(isAnimating ? 0.6 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
