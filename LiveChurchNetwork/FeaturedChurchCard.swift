import SwiftUI

struct FeaturedChurchCard: View {
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
        VStack(spacing: 0) {
            // Cover image zone — 128pt
            ZStack(alignment: .center) {
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

                // Logo avatar overlap (centered, negative offset into content)
                VStack {
                    Spacer()
                    churchLogo
                    Spacer()
                }
            }
            .frame(height: 128)
            .clipped()

            // Content zone with logo overlap space
            VStack(spacing: 8) {
                // Padding for logo overlap (50/2 = 25pt offset)
                Spacer()
                    .frame(height: 10)

                // Church name
                Text(church.name)
                    .font(.system(size: 17, weight: .black))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                // Denomination
                Text(church.denomination)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    .lineLimit(1)

                // City/State
                if !church.city.isEmpty {
                    Text(church.city)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                        .lineLimit(1)
                }

                Spacer()

                // Follow button
                if appState.currentUserId != nil {
                    FollowButton(followingId: church.slug, followingType: "church", initialIsFollowing: initialIsFollowing)
                        .frame(height: 32)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .frame(width: 280, height: 210)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.08), radius: 12, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255).opacity(0.8), lineWidth: 1)
        )
    }

    private var churchLogo: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 60, height: 60)
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)

            if !church.image.isEmpty, let url = URL(string: church.image) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    case .empty, .failure:
                        defaultChurchInitial
                    @unknown default:
                        defaultChurchInitial
                    }
                }
            } else {
                defaultChurchInitial
            }
        }
        .frame(width: 60, height: 60)
    }

    private var defaultChurchInitial: some View {
        ZStack {
            Circle().fill(Color.lcNavy)
            Text(church.name.prefix(1).uppercased())
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.lcGold)
        }
        .frame(width: 56, height: 56)
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
