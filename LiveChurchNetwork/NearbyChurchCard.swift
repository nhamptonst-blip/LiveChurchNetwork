import SwiftUI

struct NearbyChurchCard: View {
    let church: Church
    let distance: Double? // in miles
    let initialIsFollowing: Bool
    @EnvironmentObject var appState: AppState
    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 12) {
                ChurchAvatarView(church: church, size: 84, cornerRadius: 18)

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    // Church name — max 1 line
                    Text(church.name)
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .tracking(-0.2)
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                        .lineLimit(1)

                    // Meta: Denomination • City
                    Text("\(church.denomination)\(church.city.isEmpty ? "" : " • \(church.city)")")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                        .lineLimit(1)

                    // Distance if available
                    if let distance = distance {
                        Text(String(format: "%.1f", distance) + " mi away")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255))
                    }

                    Spacer()
                }

                // Follow button
                VStack(alignment: .trailing, spacing: 0) {
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
            .frame(height: 108)
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color(red: 229/255, green: 231/255, blue: 235/255).opacity(0.85), lineWidth: 1)
            )
            .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.06), radius: 10, x: 0, y: 5)

            // Live badge (top-right)
            if church.isLive {
                LiveBadge()
                    .padding(8)
            }
        }
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
