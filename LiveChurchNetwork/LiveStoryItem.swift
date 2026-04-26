import SwiftUI

struct LiveStoryItem: View {
    let church: Church
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 8) {
            // Circular image with live rings
            ZStack(alignment: .bottomTrailing) {
                // Outer red ring (3px)
                Circle()
                    .stroke(Color(red: 239/255, green: 68/255, blue: 68/255), lineWidth: 3)

                // Image
                ZStack {
                    Circle()
                        .fill(Color(red: 250/255, green: 249/255, blue: 246/255))

                    if !church.image.isEmpty, let url = URL(string: church.image) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                                    .clipShape(Circle())
                            default:
                                churchInitial
                            }
                        }
                    } else {
                        churchInitial
                    }
                }
                .padding(5) // Creates space for rings

                // Inner white ring (2px)
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .padding(3)

                // Compact live badge (bottom-right)
                CompactLiveBadge()
                    .offset(x: 6, y: 6)
            }
            .frame(width: 76, height: 76)
            .shadow(color: Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.20), radius: 8, x: 0, y: 6)

            // Church name
            Text(church.name)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                .lineLimit(2)
                .lineSpacing(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 78)

            // Viewer count
            if church.liveViewerCount > 0 {
                Text("\(church.liveViewerCount) watching")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255))
            }

            Spacer()
        }
        .frame(width: 88)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isPressed)
        .contentShape(Rectangle())
    }

    private var churchInitial: some View {
        ZStack {
            Circle().fill(Color(red: 31/255, green: 60/255, blue: 136/255))
            Text(church.name.prefix(1).uppercased())
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(red: 240/255, green: 165/255, blue: 0/255))
        }
    }
}

struct CompactLiveBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color.white)
                .frame(width: 5, height: 5)

            Text("LIVE")
                .font(.system(size: 9, weight: .bold, design: .default))
                .tracking(0.3)
                .foregroundColor(.white)
        }
        .frame(height: 20)
        .padding(.horizontal, 7)
        .background(Color(red: 239/255, green: 68/255, blue: 68/255))
        .clipShape(RoundedRectangle(cornerRadius: 999))
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(Color.white, lineWidth: 1.5)
        )
        .shadow(color: Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.24), radius: 4, x: 0, y: 3)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            LiveStoryItem(
                church: Church(
                    name: "Bethel Community",
                    slug: "bethel",
                    image: "",
                    denomination: "Non-Denominational",
                    permalink: "",
                    phone: "",
                    website: "",
                    serviceTimes: "",
                    about: "",
                    isLive: true,
                    liveViewerCount: 320
                ),
                onTap: {}
            )

            LiveStoryItem(
                church: Church(
                    name: "Grace Cathedral with a Very Long Name",
                    slug: "grace",
                    image: "",
                    denomination: "Episcopal",
                    permalink: "",
                    phone: "",
                    website: "",
                    serviceTimes: "",
                    about: "",
                    isLive: true,
                    liveViewerCount: 145
                ),
                onTap: {}
            )
        }

        HStack(spacing: 12) {
            LiveStoryItem(
                church: Church(
                    name: "St. Mary's",
                    slug: "st-marys",
                    image: "",
                    denomination: "Catholic",
                    permalink: "",
                    phone: "",
                    website: "",
                    serviceTimes: "",
                    about: "",
                    isLive: true,
                    liveViewerCount: 0
                ),
                onTap: {}
            )

            Spacer()
        }
    }
    .padding(20)
    .background(Color(red: 250/255, green: 249/255, blue: 246/255))
}
