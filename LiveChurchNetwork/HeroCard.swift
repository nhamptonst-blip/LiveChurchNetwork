import SwiftUI

struct HeroCard: View {
    var onExploreAction: () -> Void = {}
    var onWatchLiveAction: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image with overlay
            ZStack {
                // Use a solid gradient as fallback/placeholder for real image
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.3, green: 0.5, blue: 0.7),
                        Color(red: 0.2, green: 0.4, blue: 0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Overlay the image if available
                Image("lcn1")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.6)
            }
            .ignoresSafeArea(edges: .horizontal)

            // Dark gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0),
                    Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.72)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            // Content
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Find Your Church Home")
                        .font(.system(size: 24, weight: .black))
                        .tracking(-0.4)
                        .foregroundColor(.white)

                    Text("Explore live services, nearby churches, and communities growing around you.")
                        .font(.system(size: 14, weight: .medium))
                        .lineSpacing(5)
                        .foregroundColor(Color.white.opacity(0.86))
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    // Primary CTA
                    Button(action: {
                        HapticEngine.impact(.light)
                        onExploreAction()
                    }) {
                        Text("Explore Churches")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 999))
                    }

                    // Secondary CTA
                    Button(action: {
                        HapticEngine.impact(.light)
                        onWatchLiveAction()
                    }) {
                        Text("Watch Live")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.white.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 999))
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(Color.white.opacity(0.30), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 178)
        .cornerRadius(28)
        .clipped()
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.14), radius: 20, x: 0, y: 9)
        .padding(.horizontal, 20)
        .padding(.top, 22)
    }
}

#Preview {
    ZStack {
        Color(red: 250/255, green: 249/255, blue: 246/255)
            .ignoresSafeArea()

        VStack {
            HeroCard(
                onExploreAction: { print("Explore tapped") },
                onWatchLiveAction: { print("Watch Live tapped") }
            )

            Spacer()
        }
        .padding(.top, 20)
    }
}
