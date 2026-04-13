import SwiftUI

struct LiveBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
            Text("LIVE")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red)
        .cornerRadius(20)
    }
}
