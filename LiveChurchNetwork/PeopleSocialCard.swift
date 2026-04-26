import SwiftUI

struct PeopleSocialCard: View {
    let user: DiscoverableUser
    let initialIsFollowing: Bool
    let isNew: Bool
    let socialProof: String?
    @EnvironmentObject var appState: AppState
    @State private var isPressed = false

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
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 12) {
                // Avatar — 64px circular
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                    if let photoUrl = user.photoUrl, !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
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
                .frame(width: 64, height: 64)
                .flexibleFrame(minWidth: 64, maxWidth: 64)

                // Content area
                VStack(alignment: .leading, spacing: 5) {
                    // Name with leader badge
                    HStack(spacing: 8) {
                        Text(user.name)
                            .font(.system(size: 17, weight: .black))
                            .tracking(-0.1)
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .lineLimit(1)

                        if user.isLeader ?? false {
                            Text("Leader")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .frame(height: 20)
                                .background(Color(red: 37/255, green: 99/255, blue: 235/255))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }

                    // Home church — 13px, weight 700, navy (respect showHomeChurch privacy)
                    if user.showHomeChurch, let homeChurchName = user.homeChurchName {
                        Text(homeChurchName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                            .lineLimit(1)
                    } else if user.showHomeChurch == false {
                        EmptyView()
                    } else if let denomination = user.denomination {
                        Text(denomination)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                            .lineLimit(1)
                    }

                    // Bio — 13px, weight 500, max 2 lines
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                            .lineLimit(2)
                            .lineSpacing(1)
                    }

                    // Social proof — 12px, gray
                    if let proof = socialProof, !proof.isEmpty {
                        Text(proof)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255))
                            .lineLimit(1)
                    }

                    Spacer()
                }

                // Follow button — 36px height
                VStack {
                    if appState.currentUserId != nil {
                        FollowButton(
                            followingId: user.id.uuidString,
                            followingType: "worshipper",
                            initialIsFollowing: initialIsFollowing
                        )
                        .frame(height: 36)
                    }
                    Spacer()
                }
            }
            .frame(minHeight: 100)
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
            )
            .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 10, x: 0, y: 2)

            // New badge (top-right)
            if isNew {
                Text("New")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                    .padding(.horizontal, 8)
                    .frame(height: 20)
                    .background(Color(red: 255/255, green: 211/255, blue: 105/255))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(12)
            }
        }
    }

    private var defaultInitialCircle: some View {
        ZStack {
            Circle().fill(Color.lcNavy)
            Text(user.name.prefix(1).uppercased())
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.lcGold)
        }
        .frame(width: 60, height: 60)
    }
}

extension View {
    func flexibleFrame(minWidth: CGFloat? = nil, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, maxHeight: CGFloat? = nil) -> some View {
        self.frame(minWidth: minWidth, maxWidth: maxWidth, minHeight: minHeight, maxHeight: maxHeight)
    }
}

#Preview {
    VStack(spacing: 12) {
        PeopleSocialCard(
            user: DiscoverableUser(
                id: UUID(),
                name: "Sarah Johnson",
                bio: "Love praise and worship. Coffee enthusiast.",
                denomination: "Non-Denominational",
                city: "Portland, OR",
                photoUrl: nil,
                coverImageUrl: nil
            ),
            initialIsFollowing: false,
            isNew: true,
            socialProof: "Also follows Mosaic Church"
        )

        PeopleSocialCard(
            user: DiscoverableUser(
                id: UUID(),
                name: "Pastor Michael Chen",
                bio: "Serving at Mosaic Church",
                denomination: "Baptist",
                city: "Seattle, WA",
                photoUrl: nil,
                coverImageUrl: nil,
                homeChurchName: "Mosaic Church",
                isLeader: true
            ),
            initialIsFollowing: true,
            isNew: false,
            socialProof: "Shares 4 mutual connections"
        )
    }
    .padding(20)
    .background(Color(red: 250/255, green: 249/255, blue: 246/255))
    .environmentObject(AppState())
}
