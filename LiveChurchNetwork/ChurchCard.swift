import SwiftUI

struct ChurchCard: View {
    let church: Church

    private var churchInitial: String {
        String(church.name.prefix(1)).uppercased()
    }

    var body: some View {
        NavigationLink(destination: ChurchDetailView(church: church)) {
            VStack(alignment: .leading, spacing: 0) {

                // Color.lcBorder is the layout root so the AsyncImage overlay
                // can't push the card wider than its grid cell, regardless of
                // the source image's intrinsic pixel size.
                Color.lcBorder
                    .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                    .overlay {
                        Group {
                            if !church.image.isEmpty, let url = URL(string: church.image) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable().scaledToFill()
                                    case .failure:
                                        churchInitialCircle
                                    default:
                                        churchInitialCircle
                                    }
                                }
                            } else {
                                churchInitialCircle
                            }
                        }
                    }
                    .clipped()
                    .overlay(alignment: .topLeading) {
                        if church.isLive {
                            LiveBadge().padding(8)
                        }
                    }

                VStack(alignment: .leading, spacing: 5) {
                    Text(church.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.lcText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if !church.denomination.isEmpty {
                        Text(church.denomination)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.lcNavy)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.lcNavy.opacity(0.08))
                            .cornerRadius(20)
                    }

                    if !church.about.isEmpty {
                        Text(church.about)
                            .font(.system(size: 11))
                            .foregroundColor(.lcText3)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }
                .padding(10)
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var churchInitialCircle: some View {
        ZStack {
            Circle()
                .fill(Color.lcNavy.opacity(0.12))
            Text(churchInitial)
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.lcNavy)
        }
    }
}
