import SwiftUI

struct ChurchCard: View {
    let church: Church

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

    /// Solid two-tone gradient tinted by denomination. Replaces the four
    /// stock `lcn1`–`lcn4` brand photos for churches with no cover/avatar.
    /// Adds the church's first letter centered so cards still feel populated.
    private var placeholderGradient: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [gradientColors.top, gradientColors.bottom]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(churchInitial)
                .font(.system(size: 56, weight: .heavy))
                .foregroundColor(Color.white.opacity(0.18))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image and info with tap handler
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    // Background — either the church's own image, or a
                    // denomination-hashed gradient if they haven't uploaded
                    // anything. We deliberately avoid the lcn1–lcn4 brand
                    // photos when there's no church-specific image because
                    // 670 churches funneling into 4 templates makes every
                    // suggestion look identical.
                    if let coverUrlString = church.coverImage.isEmpty ? nil : church.coverImage,
                       let url = URL(string: coverUrlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                                    .overlay(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.35)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            default:
                                placeholderGradient
                            }
                        }
                    } else if !church.image.isEmpty, let url = URL(string: church.image) {
                        // No cover, but a logo exists — use a blurred-logo
                        // backdrop so the card stays per-church distinct.
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                                    .blur(radius: 18)
                                    .overlay(Color.black.opacity(0.35))
                            default:
                                placeholderGradient
                            }
                        }
                    } else {
                        // Neither cover nor avatar — clean solid gradient
                        // tinted by denomination, not a stock photo.
                        placeholderGradient
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

                    // Overlapping circular logo (white ring + centralized avatar)
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        ChurchAvatarView(church: church, size: 64)
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

        }
        .background(Color.white)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
        )
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.06), radius: 8, x: 0, y: 2)
    }

}
