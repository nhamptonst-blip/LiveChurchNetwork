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

                    // Metadata row or Watch Live button
                    if church.isLive && !church.livestreamUrl.isEmpty {
                        Button(action: {
                            HapticEngine.impact(.light)
                            if let url = URL(string: church.livestreamUrl) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Watch Live")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color(red: 239/255, green: 68/255, blue: 68/255))
                            .clipShape(RoundedRectangle(cornerRadius: 999))
                            .shadow(color: Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.24), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                    } else {
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
