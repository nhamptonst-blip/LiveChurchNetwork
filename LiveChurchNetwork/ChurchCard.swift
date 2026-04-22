import SwiftUI

struct ChurchCard: View {
    let church: Church
    var isFollowing: Bool = false
    var onFollowToggle: (() -> Void)?

    private var churchInitial: String {
        String(church.name.prefix(1)).uppercased()
    }

    // Gradient color based on denomination hash for visual variety
    private var gradientColors: (top: Color, bottom: Color) {
        let hash = church.denomination.hashValue % 5
        switch hash {
        case 0: return (Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.1, green: 0.3, blue: 0.7))
        case 1: return (Color(red: 0.8, green: 0.3, blue: 0.3), Color(red: 0.7, green: 0.2, blue: 0.2))
        case 2: return (Color(red: 0.3, green: 0.6, blue: 0.4), Color(red: 0.2, green: 0.5, blue: 0.3))
        case 3: return (Color(red: 0.8, green: 0.5, blue: 0.2), Color(red: 0.7, green: 0.4, blue: 0.1))
        default: return (Color(red: 0.6, green: 0.3, blue: 0.7), Color(red: 0.5, green: 0.2, blue: 0.6))
        }
    }

    private var backgroundImageName: String {
        let backgroundImages = ["lcn1", "lcn2", "lcn3", "lcn4"]
        let hash = abs(church.name.hashValue % 4)
        return backgroundImages[hash]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image and info with tap handler
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    // Background image (LCN brand images)
                    Image(backgroundImageName)
                        .resizable()
                        .scaledToFill()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Church's custom cover image (if available)
                    if !church.image.isEmpty, let url = URL(string: church.image) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                                    .opacity(0.0)
                            default:
                                EmptyView()
                            }
                        }
                    }

                    // Live badge (if applicable)
                    if church.isLive {
                        HStack(spacing: 4) {
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Text("LIVE NOW")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(8)
                        .padding(10)
                    }

                    // Overlapping circular logo
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

                        if !church.image.isEmpty, let url = URL(string: church.image) {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(Circle())
                                } else {
                                    churchInitialCircle
                                }
                            }
                        } else {
                            churchInitialCircle
                        }
                    }
                    .offset(x: 12, y: 28)
                }
                .frame(height: 140)
                .clipped()

                // Content area
                VStack(alignment: .leading, spacing: 8) {
                    Spacer().frame(height: 20)
                    Text(church.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.lcText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if !church.denomination.isEmpty {
                        Text(church.denomination)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.lcNavy)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.lcNavy.opacity(0.08))
                            .cornerRadius(6)
                    }

                    if !church.about.isEmpty {
                        Text(church.about)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.lcText2)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(14)
                .padding(.bottom, 0)
            }

            // Follow button (separate, not in NavigationLink)
            if let onFollowToggle = onFollowToggle {
                VStack {
                    Spacer()
                    Button(action: {
                        onFollowToggle()
                        HapticEngine.impact(isFollowing ? .light : .medium)
                    }) {
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isFollowing ? .lcNavy : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isFollowing ? Color.white : Color.lcNavy)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.lcNavy, lineWidth: isFollowing ? 1.5 : 0)
                            )
                            .shadow(color: isFollowing ? Color.clear : Color.lcNavy.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(14)
                .padding(.top, 0)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
    }

    private var churchInitialCircle: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.3))
            Text(churchInitial)
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white)
        }
    }
}
