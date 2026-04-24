import SwiftUI

struct PeopleDiscoveryCard: View {
    let user: DiscoverableUser
    @EnvironmentObject var appState: AppState

    private var defaultGradient: LinearGradient {
        let hash = (user.denomination ?? "").hashValue % 5
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
            // Cover image - exactly 100px
            ZStack {
                if let coverUrl = user.coverImageUrl, !coverUrl.isEmpty, let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .clipped()
                        case .empty, .failure:
                            defaultGradient
                        @unknown default:
                            defaultGradient
                        }
                    }
                } else {
                    defaultGradient
                }
            }
            .frame(height: 100)
            .clipped()

            // Profile photo overlap zone - 60px height for spacing
            ZStack(alignment: .top) {
                // Spacer to push profile down
                Color.clear.frame(height: 30)

                // Profile photo (overlaps cover and body)
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        profilePhoto
                        Spacer()
                    }
                    Spacer()
                }
                .frame(height: 60)
            }
            .frame(height: 60)

            // Body content - exactly 90px
            VStack(spacing: 8) {
                Text(user.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lcText)
                    .lineLimit(1)

                Text(user.denomination ?? "Worshipper")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.lcText3)
                    .lineLimit(1)

                Spacer()

                if appState.currentUserId != nil {
                    FollowButton(followingId: user.id.uuidString, followingType: "worshipper")
                        .frame(height: 32)
                }
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
    }

    private var profilePhoto: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 60, height: 60)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            if let photoUrl = user.photoUrl, !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    case .empty, .failure:
                        defaultInitialCircle
                    @unknown default:
                        defaultInitialCircle
                    }
                }
            } else {
                defaultInitialCircle
            }
        }
        .frame(width: 60, height: 60)
    }

    private var defaultInitialCircle: some View {
        ZStack {
            Circle().fill(Color.lcNavy)
            Text(user.name.prefix(1).uppercased())
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.lcGold)
        }
        .frame(width: 56, height: 56)
    }
}

// Skeleton loading card
struct PeopleDiscoveryCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            // Cover skeleton
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.lcBorder.opacity(0.5))
                .frame(height: 100)

            // Profile zone
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

            // Body skeleton
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
            withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                isAnimating = true
            }
        }
    }
}
