import SwiftUI

struct LiveStoriesRow: View {
    let liveChurches: [Church]

    var body: some View {
        if liveChurches.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("🔴 Live Now")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lcText3)
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(liveChurches, id: \.slug) { church in
                            NavigationLink(destination: ChurchDetailView(church: church)) {
                                LiveStoryCircle(church: church)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 12)
        }
    }
}

struct LiveStoryCircle: View {
    let church: Church
    @State private var pulsing = false

    var body: some View {
        VStack(spacing: 8) {
            // Circle with red ring and pulsing effect
            ZStack(alignment: .bottomTrailing) {
                // Outer red ring (2pt)
                Circle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: 72, height: 72)

                // Inner circle with image
                ZStack {
                    // Gradient or image
                    if !church.image.isEmpty, let url = URL(string: church.image) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            default:
                                churchGradient
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            }
                        }
                    } else {
                        churchGradient
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    }
                }

                // Pulsing red dot (bottom-trailing)
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(Color.red.opacity(0.3), lineWidth: 2)
                                .scaleEffect(pulsing ? 1.8 : 1.0)
                                .opacity(pulsing ? 0 : 1)
                                .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: pulsing)
                        )
                        .shadow(color: Color.red.opacity(0.6), radius: 4, x: 0, y: 2)
                }
                .offset(x: 3, y: 3)
            }

            // Church name below
            Text(church.name.prefix(16))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.lcText)
                .lineLimit(1)
                .frame(width: 72, alignment: .center)
        }
        .onAppear { pulsing = true }
    }

    private var churchGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.lcNavy.opacity(0.5),
                Color.lcTeal.opacity(0.5)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    LiveStoriesRow(
        liveChurches: [
            Church(
                name: "Bethel Live",
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
    .padding()
}
