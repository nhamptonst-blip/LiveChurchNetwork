import SwiftUI

struct PeopleDiscoveryCard: View {
    let user: DiscoverableUser
    let initialIsFollowing: Bool
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
        VStack(spacing: 0) {
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

            ZStack(alignment: .top) {
                Color.clear.frame(height: 30)

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

            VStack(spacing: 8) {
                Text(user.name)
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.lcText)
                    .lineLimit(1)

                let subtitle = (user.showHomeChurch ? user.homeChurchName : nil) ?? user.denomination ?? "Worshipper"
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.lcText3)
                    .lineLimit(1)

                Spacer()

                if appState.currentUserId != nil {
                    FollowButton(followingId: user.id.uuidString, followingType: "worshipper", initialIsFollowing: initialIsFollowing)
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
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
        )
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.06), radius: 8, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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
