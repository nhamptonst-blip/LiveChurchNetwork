import SwiftUI

struct DirectoryChurchCard: View {
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
            // Cover image — 112pt
            ZStack(alignment: .bottom) {
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

                // Logo overlap — 44pt with 3pt white border
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)

                    if !church.image.isEmpty, let url = URL(string: church.image) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                                    .frame(width: 38, height: 38)
                                    .clipShape(Circle())
                            case .empty, .failure:
                                churchInitial
                            @unknown default:
                                churchInitial
                            }
                        }
                    } else {
                        churchInitial
                    }
                }
                .frame(width: 44, height: 44)
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .offset(y: 22)
            }
            .frame(height: 112)
            .clipped()

            // Content area
            VStack(alignment: .leading, spacing: 8) {
                // Top padding for logo overlap
                Spacer()
                    .frame(height: 12)

                // Church name — max 2 lines
                Text(church.name)
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                    .lineLimit(2)
                    .lineSpacing(0)

                // Denomination
                Text(church.denomination)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    .lineLimit(1)

                // Location
                if !church.city.isEmpty {
                    Text(church.city)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255))
                        .lineLimit(1)
                }

                // Stats row
                HStack(spacing: 8) {
                    if church.followerCount > 0 {
                        Text(formatCount(church.followerCount) + " followers")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    }

                    if church.isLive {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color(red: 239/255, green: 68/255, blue: 68/255))
                                .frame(width: 4, height: 4)

                            Text("320 live")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                        }
                    }
                }
                .lineLimit(1)

                Spacer()

                // Follow button
                if appState.currentUserId != nil {
                    FollowButton(
                        followingId: church.slug,
                        followingType: "church",
                        initialIsFollowing: initialIsFollowing
                    )
                    .frame(height: 32)
                }
            }
            .padding(.top, 0)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(minHeight: 230)
        .background(Color.white)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
        )
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.06), radius: 8, x: 0, y: 2)
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
