import SwiftUI

struct PremiumPersonCard: View {
    let user: DiscoverableUser
    let initialIsFollowing: Bool
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Cover (80pt)
            ZStack {
                if let coverUrl = user.coverImageUrl, !coverUrl.isEmpty, let url = URL(string: coverUrl) {
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
            }
            .frame(height: 80)
            .clipped()

            // MARK: - Avatar Overlap & Body
            VStack(alignment: .center, spacing: 10) {
                // Avatar overlap (centered, -28 offset)
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)

                    if let photoUrl = user.photoUrl, !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                                    .frame(width: 68, height: 68)
                                    .clipShape(Circle())
                            default:
                                userInitialCircle
                            }
                        }
                    } else {
                        userInitialCircle
                    }
                }
                .frame(width: 72, height: 72)
                .offset(y: -36)
                .padding(.top, -36)

                // Name
                Text(user.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.lcText)
                    .lineLimit(1)

                // Home Church (privacy-gated)
                if user.churchesPrivacy.isPublic, let homeChurch = user.homeChurchName, !homeChurch.isEmpty {
                    Text("@ \(homeChurch)")
                        .font(.system(size: 11))
                        .foregroundColor(.lcText3)
                        .lineLimit(1)
                }

                // Bio snippet (privacy-gated)
                if user.activityPrivacy.isPublic, let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 12))
                        .foregroundColor(.lcText2)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Denomination badge
                if let denomination = user.denomination, !denomination.isEmpty {
                    Text(denomination)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.lcNavy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.lcNavy.opacity(0.08))
                        .cornerRadius(8)
                }

                // Follow button (full width)
                if appState.currentUserId != nil {
                    FollowButton(
                        followingId: user.id.uuidString,
                        followingType: "worshipper",
                        initialIsFollowing: initialIsFollowing
                    )
                    .frame(height: 32)
                    .padding(.top, 4)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(Color.white)
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
        .background(Color.white)
    }

    private var userInitialCircle: some View {
        ZStack {
            Circle().fill(Color.lcNavy)
            Text(String(user.name.prefix(1).uppercased()))
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.lcGold)
        }
    }

    private var denominationGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.lcTeal.opacity(0.25),
                Color.lcNavy.opacity(0.15)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - PrivacySetting Extension

extension PrivacySetting {
    var isPublic: Bool {
        self == .public
    }
}

#Preview {
    PremiumPersonCard(
        user: DiscoverableUser(
            id: UUID(),
            name: "Sarah Johnson",
            bio: "Worship leader and faith explorer",
            denomination: "Baptist",
            city: "Nashville, TN",
            photoUrl: nil,
            coverImageUrl: nil,
            homeChurchName: "Hillside Church",
            followerCount: 45,
            followingCount: 127,
            activityPrivacy: .public,
            churchesPrivacy: .public
        ),
        initialIsFollowing: false
    )
    .environmentObject(AppState())
    .padding()
}
