import SwiftUI

struct LiveStoriesRow: View {
    let liveChurches: [Church]

    var body: some View {
        if liveChurches.isEmpty {
            // MARK: - Empty State
            VStack(alignment: .leading, spacing: 16) {
                Text("No churches are live right now")
                    .font(.system(size: 22, weight: .black))
                    .tracking(-0.6)
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                Text("Explore featured churches or check back during service times.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                Button(action: {}) {
                    Text("Browse Churches")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(red: 31/255, green: 60/255, blue: 136/255))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Now")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                    Text("Join services happening right now")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                }
                .padding(.horizontal, 20)

                // MARK: - Stories Row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(liveChurches, id: \.slug) { church in
                            NavigationLink(destination: ChurchDetailView(church: church)) {
                                LiveStoryItem(church: church)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 12)
        }
    }
}

struct LiveStoryItem: View {
    let church: Church
    @State private var pulsing = false

    var body: some View {
        VStack(spacing: 8) {
            // MARK: - Story Circle with Red Border
            ZStack(alignment: .bottomTrailing) {
                // Outer red border (3px)
                Circle()
                    .stroke(Color(red: 239/255, green: 68/255, blue: 68/255), lineWidth: 3)
                    .frame(width: 80, height: 80)

                // Inner white ring (2px)
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 74, height: 74)

                // Image/gradient inside
                ZStack {
                    if !church.image.isEmpty, let url = URL(string: church.image) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                            default:
                                churchGradient
                            }
                        }
                    } else {
                        churchGradient
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(Circle())

                // MARK: - Live Pill (bottom-right overlay)
                HStack(spacing: 2) {
                    Circle()
                        .fill(Color(red: 239/255, green: 68/255, blue: 68/255))
                        .frame(width: 4, height: 4)

                    Text("LIVE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                }
                .frame(height: 20)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color(red: 239/255, green: 68/255, blue: 68/255))
                .cornerRadius(999)
                .offset(x: 4, y: 4)
            }

            // MARK: - Church Name
            Text(church.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                .lineLimit(2)
                .frame(width: 80, alignment: .center)
                .multilineTextAlignment(.center)
        }
        .onAppear { pulsing = true }
    }

    private var churchGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 31/255, green: 60/255, blue: 136/255),
                Color(red: 91/255, green: 143/255, blue: 168/255)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    VStack {
        LiveStoriesRow(
            liveChurches: [
                Church(
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
                Church(
                    name: "Grace Cathedral",
                    slug: "grace-cathedral",
                    image: "",
                    denomination: "Episcopal",
                    permalink: "",
                    phone: "",
                    website: "",
                    serviceTimes: "",
                    about: "",
                    isLive: true
                )
            ]
        )

        Divider()

        LiveStoriesRow(liveChurches: [])
    }
    .padding()
}
