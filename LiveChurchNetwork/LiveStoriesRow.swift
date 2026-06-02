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

                NavigationLink(destination: DirectoryView()) {
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
                        ForEach(liveChurches, id: \.id) { church in
                            NavigationLink(destination: ChurchDetailView(church: church)) {
                                LiveStoryItem(church: church, onTap: {})
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
