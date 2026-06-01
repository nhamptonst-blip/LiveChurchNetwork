import SwiftUI

struct ChurchDiscoveryCard: View {
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
        VStack(spacing: 0) {
            // Cover zone — 120pt
            ZStack(alignment: .topTrailing) {
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
                    HStack(spacing: 4) {
                        Image(systemName: "dot.circle.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("Live")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.9, green: 0.2, blue: 0.2))
                    .cornerRadius(12)
                    .padding(12)
                }
            }
            .frame(height: 120)
            .clipped()

            // Logo overlap zone — 50pt
            ZStack(alignment: .top) {
                Color.clear.frame(height: 28)

                HStack {
                    Spacer()
                    churchLogo
                    Spacer()
                }
                .frame(height: 50)
            }
            .frame(height: 50)

            // Body — 70pt remaining (240 total - 120 cover - 50 overlap)
            VStack(spacing: 8) {
                Text(church.name)
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.lcText)
                    .lineLimit(1)

                if !church.address.isEmpty {
                    Text(church.address)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.lcText3)
                        .lineLimit(1)
                } else {
                    Text(church.denomination)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.lcText3)
                        .lineLimit(1)
                }

                Spacer()

                if appState.currentUserId != nil {
                    FollowButton(followingId: church.slug, followingType: "church", initialIsFollowing: initialIsFollowing)
                        .frame(height: 32)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(height: 70)
        }
        .frame(height: 240)
        .background(Color.white)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
        )
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var churchLogo: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            ChurchAvatarView(church: church, size: 46)
        }
        .frame(width: 50, height: 50)
    }

}
