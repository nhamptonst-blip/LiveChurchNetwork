import SwiftUI

struct LiveView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Live")
                    .font(.system(size: 34, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                Text("Watch live services from churches in your community")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "play.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.lcNavy)

                    Text("No livestreams currently")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)

                    Text("Check back soon for live services")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .background(Color(red: 0.98, green: 0.97, blue: 0.96))
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    LiveView()
}
