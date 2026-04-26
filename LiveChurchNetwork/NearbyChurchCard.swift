import SwiftUI

struct NearbyChurchCard: View {
    let church: Church
    let distance: Double? // in miles
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
            // Left image — 80px square
            ZStack {
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

                // Live badge overlay if live
                if church.isLive {
                    VStack(alignment: .leading) {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color(red: 239/255, green: 68/255, blue: 68/255))
                                .frame(width: 4, height: 4)

                            Text("LIVE")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(Color(red: 239/255, green: 68/255, blue: 68/255))
                        .cornerRadius(4)
                        .padding(6)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(16)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Church name
                Text(church.name)
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                    .lineLimit(1)

                // Denomination
                Text(church.denomination)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    .lineLimit(1)

                // City and distance
                HStack(spacing: 4) {
                    if !church.city.isEmpty {
                        Text(church.city)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                            .lineLimit(1)
                    }

                    if let distance = distance {
                        Text("• \(String(format: "%.1f", distance)) mi away")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            // Follow button
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
        .frame(height: 104)
        .padding(12)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
        )
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 12) {
        NearbyChurchCard(
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
            distance: 2.4,
            initialIsFollowing: false
        )

        NearbyChurchCard(
            church: Church(
                name: "Bethel Live",
                slug: "bethel-live",
                image: "",
                denomination: "Pentecostal",
                permalink: "",
                phone: "",
                website: "",
                serviceTimes: "",
                about: "",
                isLive: true
            ),
            distance: 1.2,
            initialIsFollowing: false
        )
    }
    .padding()
    .environmentObject(AppState())
}
