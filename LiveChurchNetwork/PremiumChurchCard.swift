import SwiftUI

struct PremiumChurchCard: View {
    let church: Church
    let initialIsFollowing: Bool
    @EnvironmentObject var appState: AppState
    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // MARK: - Cover Image (130pt)
                ZStack(alignment: .bottomLeading) {
                    // Cover image or gradient
                    if !church.coverImage.isEmpty, let url = URL(string: church.coverImage) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            default:
                                Color.lcBorder
                            }
                        }
                    } else {
                        denominationGradient
                    }

                    // Gradient overlay (clear to black 0.45 from 60% down)
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0),
                            Color.black.opacity(0.45)
                        ]),
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )

                    // City label (bottom-leading)
                    if !church.city.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 10))
                            Text(church.city)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.4), radius: 2)
                        .padding(10)
                    }
                }
                .frame(height: 130)
                .clipped()

                // MARK: - Avatar Overlap & Body
                VStack(alignment: .leading, spacing: 8) {
                    // Avatar overlap zone
                    HStack(spacing: 12) {
                        // Church Logo/Avatar
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)

                            if !church.image.isEmpty, let url = URL(string: church.image) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    default:
                                        churchInitialCircle
                                    }
                                }
                            } else {
                                churchInitialCircle
                            }
                        }
                        .frame(width: 44, height: 44)
                        .offset(y: -22)

                        Spacer()
                    }
                    .padding(.horizontal, 12)

                    // Name
                    Text(church.name)
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.lcText)
                        .lineLimit(2)
                        .padding(.horizontal, 12)

                    // Denomination
                    if !church.denomination.isEmpty {
                        Text(church.denomination)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.lcText3)
                            .padding(.horizontal, 12)
                    }

                    // Metadata row: followers + Follow button
                    HStack(spacing: 10) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                            Text(formatCount(church.followerCount))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.lcText3)

                        Spacer()

                        if appState.currentUserId != nil {
                            FollowButton(
                                followingId: church.slug,
                                followingType: "church",
                                initialIsFollowing: initialIsFollowing
                            )
                            .frame(height: 34)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
                .background(Color.white)
            }
            .cornerRadius(22)
            .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.08), radius: 12, x: 0, y: 4)
            .background(Color.white)

            // MARK: - Badges (top-trailing)
            VStack(spacing: 6) {
                if church.isLive {
                    LiveBadgeAnimated()
                }
                if !church.city.isEmpty && church.followerCount > 500 {
                    TrendingBadge()
                }
            }
            .padding(10)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var churchInitialCircle: some View {
        ZStack {
            Circle().fill(Color.lcNavy)
            Text(String(church.name.prefix(1).uppercased()))
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.lcGold)
        }
    }

    private var denominationGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.lcNavy.opacity(0.3),
                Color.lcTeal.opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000).replacingOccurrences(of: ".0k", with: "k")
        }
        return String(count)
    }
}

// MARK: - Badge Components

struct LiveBadgeAnimated: View {
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .stroke(Color.red.opacity(0.4), lineWidth: 2)
                            .scaleEffect(pulsing ? 1.6 : 1.0)
                            .opacity(pulsing ? 0 : 1)
                            .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: pulsing)
                    )
            }

            Text("LIVE")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.9))
        .cornerRadius(12)
        .onAppear { pulsing = true }
    }
}

struct TrendingBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 8))
            Text("TRENDING")
                .font(.system(size: 8, weight: .black))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.85))
        .cornerRadius(12)
    }
}

struct NewBadge: View {
    var body: some View {
        Text("NEW")
            .font(.system(size: 9, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.lcTeal.opacity(0.85))
            .cornerRadius(12)
    }
}

#Preview {
    PremiumChurchCard(
        church: Church(
            name: "Grace Community Church",
            slug: "grace-community-church",
            image: "",
            denomination: "Non-Denominational",
            permalink: "",
            phone: "",
            website: "gracechurch.com",
            serviceTimes: "Sun 9am, 11am",
            about: "A welcoming community",
            city: "Los Angeles, CA",
            pastorName: "Pastor John",
            followerCount: 2400,
            livestreamUrl: ""
        ),
        initialIsFollowing: false
    )
    .environmentObject(AppState())
    .padding()
}
