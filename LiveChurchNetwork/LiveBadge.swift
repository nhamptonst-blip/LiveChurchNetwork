import SwiftUI

struct LiveBadge: View {
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)

            Text("LIVE")
                .font(.system(size: 10, weight: .bold, design: .default))
                .tracking(0.4)
                .foregroundColor(.white)
        }
        .frame(height: 24)
        .padding(.horizontal, 9)
        .background(Color(red: 239/255, green: 68/255, blue: 68/255))
        .clipShape(RoundedRectangle(cornerRadius: 999))
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(color: Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.28), radius: 6, x: 0, y: 6)
    }
}

struct LiveBadgeAnimated: View {
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .scaleEffect(pulsing ? 1.35 : 1.0)
                    .opacity(pulsing ? 0.55 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                        value: pulsing
                    )
            }

            Text("LIVE")
                .font(.system(size: 10, weight: .bold, design: .default))
                .tracking(0.4)
                .foregroundColor(.white)
        }
        .frame(height: 24)
        .padding(.horizontal, 9)
        .background(Color(red: 239/255, green: 68/255, blue: 68/255))
        .clipShape(RoundedRectangle(cornerRadius: 999))
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(color: Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.28), radius: 6, x: 0, y: 6)
        .onAppear { pulsing = true }
    }
}
