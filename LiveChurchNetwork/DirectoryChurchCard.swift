import SwiftUI

struct DirectoryChurchCard: View {
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
                // Cover image — 118pt
                ZStack(alignment: .bottom) {
                    if !church.image.isEmpty, let url = URL(string: church.image) {
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

                    // Logo overlap — 42pt with 3pt white border
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 42, height: 42)

                        if !church.image.isEmpty, let url = URL(string: church.image) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable()
                                        .scaledToFill()
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())
                                default:
                                    churchInitial
                                }
                            }
                        } else {
                            churchInitial
                        }
                    }
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .offset(y: 21)
                }
                .frame(height: 118)
                .clipped()

                // Content area
                VStack(alignment: .leading, spacing: 6) {
                    Spacer().frame(height: 14)

                    // Church name — max 2 lines
                    Text(church.name)
                        .font(.system(size: 15, weight: .bold, design: .default))
                        .tracking(-0.2)
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                        .lineLimit(2)
                        .lineSpacing(1)

                    // Meta: Denomination • City
                    Text("\(church.denomination)\(church.city.isEmpty ? "" : " • \(church.city)")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                        .lineLimit(1)

                    // Stats: followers if available
                    if church.followerCount > 0 {
                        Text(formatCount(church.followerCount) + " followers")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255))
                    }

                    Spacer()

                    // Follow button — full width
                    if appState.currentUserId != nil {
                        FollowButton(
                            followingId: church.slug,
                            followingType: "church",
                            initialIsFollowing: initialIsFollowing
                        )
                        .frame(height: 32)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .frame(minHeight: 236)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(red: 229/255, green: 231/255, blue: 235/255).opacity(0.85), lineWidth: 1)
            )
            .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.07), radius: 10, x: 0, y: 5)

            // Badge (top-left) — max 1 badge
            if church.isLive {
                LiveBadge()
                    .padding(8)
            } else if church.isVerified {
                VerifiedBadge(compact: true)
                    .padding(8)
            } else if church.isTrending {
                TrendingBadge(compact: true)
                    .padding(8)
            } else if church.isNew {
                NewBadge(compact: true)
                    .padding(8)
            }
        }
    }

    private var churchInitial: some View {
        ZStack {
            Circle().fill(Color.lcNavy)
            Text(church.name.prefix(1).uppercased())
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lcGold)
        }
        .frame(width: 38, height: 38)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return String(count)
    }
}

#Preview {
    VStack(spacing: 14) {
        HStack(spacing: 14) {
            DirectoryChurchCard(
                church: Church(
                    name: "Bethel Live Church Community",
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

            DirectoryChurchCard(
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
                initialIsFollowing: true
            )
        }
    }
    .padding(20)
    .environmentObject(AppState())
}

extension Circle {
    func border(_ shape: Circle, width: CGFloat, color: Color) -> some View {
        ZStack {
            shape
                .stroke(color, lineWidth: width)
            self
        }
    }
}
