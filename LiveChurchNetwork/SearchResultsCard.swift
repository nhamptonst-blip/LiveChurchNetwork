import SwiftUI

// MARK: - Church Search Result Card

struct ChurchSearchResultCard: View {
    let church: Church
    let initialIsFollowing: Bool
    @EnvironmentObject var appState: AppState

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
        HStack(spacing: 12) {
            // Cover image or logo — 72pt
            ZStack(alignment: .bottomTrailing) {
                if !church.image.isEmpty, let url = URL(string: church.image) {
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

                // Live badge
                if church.isLive {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(Color(red: 239/255, green: 68/255, blue: 68/255))
                            .frame(width: 4, height: 4)

                        Text("LIVE")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(red: 239/255, green: 68/255, blue: 68/255))
                    .cornerRadius(4)
                    .padding(6)
                }
            }
            .frame(width: 72, height: 72)
            .cornerRadius(12)
            .clipped()

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(church.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                    .lineLimit(1)

                Text(church.denomination)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    .lineLimit(1)

                if !church.city.isEmpty {
                    Text(church.city)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255))
                        .lineLimit(1)
                }

                Spacer()
            }

            VStack {
                if appState.currentUserId != nil {
                    FollowButton(
                        followingId: church.slug,
                        followingType: "church",
                        initialIsFollowing: initialIsFollowing
                    )
                    .frame(height: 32)
                }
                Spacer()
            }
        }
        .frame(minHeight: 88)
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
        )
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - People Search Result Row

struct PeopleSearchResultRow: View {
    let user: DiscoverableUser
    let initialIsFollowing: Bool
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
        HStack(spacing: 12) {
            // Avatar — 56px
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                if let photoUrl = user.photoUrl, !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
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
            .frame(width: 56, height: 56)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                    .lineLimit(1)

                if let homeChurchName = user.homeChurchName {
                    Text(homeChurchName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                        .lineLimit(1)
                } else if let denomination = user.denomination {
                    Text(denomination)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                        .lineLimit(1)
                }

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                        .lineLimit(1)
                }

                Spacer()
            }

            VStack {
                if appState.currentUserId != nil {
                    FollowButton(
                        followingId: user.id.uuidString,
                        followingType: "worshipper",
                        initialIsFollowing: initialIsFollowing
                    )
                    .frame(height: 32)
                }
                Spacer()
            }
        }
        .frame(minHeight: 80)
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
        )
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var defaultInitialCircle: some View {
        ZStack {
            Circle().fill(Color.lcNavy)
            Text(user.name.prefix(1).uppercased())
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.lcGold)
        }
        .frame(width: 52, height: 52)
    }
}

#Preview {
    VStack(spacing: 12) {
        ChurchSearchResultCard(
            church: Church(
                name: "Grace Cathedral",
                slug: "grace-cathedral",
                image: "",
                denomination: "Episcopal",
                permalink: "",
                phone: "",
                website: "",
                serviceTimes: "",
                about: "",
                isLive: false
            ),
            initialIsFollowing: false
        )

        PeopleSearchResultRow(
            user: DiscoverableUser(
                id: UUID(),
                name: "Sarah Johnson",
                bio: "Coffee enthusiast, loves worship",
                denomination: "Baptist",
                city: "Portland, OR",
                photoUrl: nil,
                coverImageUrl: nil
            ),
            initialIsFollowing: false
        )
    }
    .padding(20)
    .environmentObject(AppState())
}
