import SwiftUI

struct VerifiedBadge: View {
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: compact ? 8 : 10, weight: .bold))

            Text("Verified")
                .font(.system(size: compact ? 9 : 10, weight: .bold, design: .default))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .frame(height: compact ? 20 : 22)
        .background(Color(red: 37/255, green: 99/255, blue: 235/255))
        .clipShape(RoundedRectangle(cornerRadius: 999))
    }
}

struct TrendingBadge: View {
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: compact ? 8 : 10, weight: .bold))

            Text("Trending")
                .font(.system(size: compact ? 9 : 10, weight: .bold, design: .default))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .frame(height: compact ? 20 : 22)
        .background(Color(red: 124/255, green: 58/255, blue: 237/255))
        .clipShape(RoundedRectangle(cornerRadius: 999))
    }
}

struct NewBadge: View {
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: compact ? 8 : 10, weight: .bold))

            Text("New")
                .font(.system(size: compact ? 9 : 10, weight: .bold, design: .default))
        }
        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
        .padding(.horizontal, 8)
        .frame(height: compact ? 20 : 22)
        .background(Color(red: 255/255, green: 211/255, blue: 105/255))
        .clipShape(RoundedRectangle(cornerRadius: 999))
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 8) {
            VerifiedBadge()
            TrendingBadge()
            NewBadge()
        }

        HStack(spacing: 8) {
            VerifiedBadge(compact: true)
            TrendingBadge(compact: true)
            NewBadge(compact: true)
        }
    }
    .padding(20)
    .background(Color(red: 250/255, green: 249/255, blue: 246/255))
}
