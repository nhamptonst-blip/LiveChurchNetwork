import SwiftUI

struct FeaturedChurchCard: View {
    let church: Church
    let initialIsFollowing: Bool
    @EnvironmentObject var appState: AppState
    @State private var isPressed = false

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
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                // Cover image — 150pt with gradient overlay
                ZStack(alignment: .bottomLeading) {
                    if !church.coverImage.isEmpty, let url = URL(string: church.coverImage) {
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

                    // Bottom gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0),
                            Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.38)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Logo overlap (white ring + centralized avatar)
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 48, height: 48)
                        ChurchAvatarView(church: church, size: 42)
                    }
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .padding(12)
                }
                .frame(height: 150)
                .clipped()

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Spacer().frame(height: 12)

                    // Church name
                    Text(church.name)
                        .font(.system(size: 17, weight: .bold, design: .default))
                        .tracking(-0.2)
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                        .lineLimit(2)

                    // Meta: Denomination • City, State
                    Text("\(church.denomination)\(church.city.isEmpty ? "" : " • \(church.city)")")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                        .lineLimit(1)

                    // Stats
                    if church.followerCount > 0 {
                        Text("\(formatCount(church.followerCount)) followers")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255))
                    }

                    Spacer()

                    // Follow button
                    if appState.currentUserId != nil {
                        FollowButton(
                            followingId: church.slug,
                            followingType: "church",
                            initialIsFollowing: initialIsFollowing
                        )
                        .frame(height: 32)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            .frame(width: 300, height: 240)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color(red: 229/255, green: 231/255, blue: 235/255).opacity(0.7), lineWidth: 1)
            )
            .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.10), radius: 16, x: 0, y: 9)

            // Badges (top-left and top-right)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    // Top-left: Live badge
                    if church.isLive {
                        LiveBadge()
                    }

                    Spacer()

                    // Top-right: Verified/Trending/New (priority order)
                    if church.isVerified {
                        VerifiedBadge()
                    } else if church.isTrending {
                        TrendingBadge()
                    } else if church.isNew {
                        NewBadge()
                    }
                }
                Spacer()
            }
            .padding(12)
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return String(count)
    }
}

#Preview {
    FeaturedChurchCard(
        church: Church(
            name: "Bethel Live Church",
            slug: "bethel-live",
            image: "",
            denomination: "Non-Denominational",
            permalink: "",
            phone: "",
            website: "",
            serviceTimes: "",
            about: "",
            isLive: true
        ),
        initialIsFollowing: false
    )
    .environmentObject(AppState())
}
