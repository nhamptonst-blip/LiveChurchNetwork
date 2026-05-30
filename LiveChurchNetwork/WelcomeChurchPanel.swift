import SwiftUI

/// "Welcome to {Church}" panel — the primary public-profile content card.
/// Replaces the old sidebar About card. Renders mission, denomination,
/// location, livestream/website, "what to expect", structured service times
/// preview, ministries chips, and a footer link cluster.
///
/// Mirrors web's <ChurchWelcomeAbout/> 1:1.
struct WelcomeChurchPanel: View {
    let church: ChurchSubmission

    var body: some View {
        // Render only when the church has at least one populated field.
        if !hasAnything { EmptyView() } else {
            VStack(alignment: .leading, spacing: 0) {
                header
                content
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.lcGoldLight.opacity(0.4),
                        Color.white,
                        Color.lcCream.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.lcBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WELCOME")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.8)
                .foregroundColor(.lcGold)

            Text("Welcome to \(church.churchName ?? "Our Church")")
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(.lcText)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            if let denom = church.denomination, !denom.isEmpty {
                HStack(spacing: 6) {
                    Text(denom)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lcText2)
                    if let location = locationString {
                        Text("·").foregroundColor(.lcText3)
                        Text(location)
                            .font(.system(size: 14))
                            .foregroundColor(.lcText3)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let about = church.about, !about.isEmpty {
                Text(about)
                    .font(.system(size: 16))
                    .foregroundColor(.lcText2)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Fact tiles — stacked vertically so each gets the full row width
            // on phone screens. (Three across was too narrow for "Catholic"
            // to fit and made "TRADITION" wrap into three letter-stacks.)
            VStack(spacing: 8) {
                if let denom = church.denomination, !denom.isEmpty {
                    factTile(icon: "✝️", label: "TRADITION", value: denom)
                }
                if let location = locationString {
                    factTile(icon: "📍", label: "LOCATION", value: location)
                }
                liveOrLinkTile
            }

            // What to expect
            if let wte = church.whatToExpect, !wte.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("WHAT TO EXPECT")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(.lcText3)
                    Text(wte)
                        .font(.system(size: 14))
                        .foregroundColor(.lcText2)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.lcBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Structured service times
            if !services.isEmpty {
                ServiceTimesDisplay(services: services, initialRowLimit: 2)
            }

            // Ministries
            if !ministries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MINISTRIES")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(.lcText3)
                    FlowLayout(spacing: 8) {
                        ForEach(ministries, id: \.self) { m in
                            Text(m)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Color.white)
                                .foregroundColor(.lcText2)
                                .overlay(
                                    Capsule().stroke(Color.lcBorder, lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Footer link cluster — FlowLayout so pills keep their natural
            // width (HStack was squeezing them so narrow that labels wrapped
            // character-by-character).
            if hasAnyExternalLink {
                FlowLayout(spacing: 8) {
                    if let url = church.website, !url.isEmpty {
                        FooterLink(href: url, icon: "🌐", label: "Website")
                    }
                    if let url = church.donationUrl, !url.isEmpty {
                        FooterLink(href: url, icon: "💝", label: "Give")
                    }
                    if let url = church.facebookUrl, !url.isEmpty {
                        FooterLink(href: url, icon: "📘", label: "Facebook")
                    }
                    if let url = church.instagramUrl, !url.isEmpty {
                        FooterLink(href: url, icon: "📷", label: "Instagram")
                    }
                    if let url = church.youtubeUrl, !url.isEmpty {
                        FooterLink(href: url, icon: "▶️", label: "YouTube")
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Subviews

    private func factTile(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(icon)
                .font(.system(size: 22))
                .frame(width: 28, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.lcText3)
                    .lineLimit(1)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lcText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var liveOrLinkTile: some View {
        if let live = church.livestreamUrl, !live.isEmpty {
            let isLive = church.isLive
            Link(destination: URL(string: live) ?? URL(string: "https://livechurchnetwork.com")!) {
                HStack(alignment: .top, spacing: 10) {
                    Text("📡").font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LIVESTREAM")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(.lcText3)
                        HStack(spacing: 6) {
                            if isLive {
                                Circle().fill(Color.red).frame(width: 6, height: 6)
                            }
                            Text(isLive ? "Live now" : "Available")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(isLive ? .red : .lcText)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isLive ? Color.red.opacity(0.04) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isLive ? Color.red.opacity(0.3) : Color.lcBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        } else if let site = church.website, !site.isEmpty {
            Link(destination: URL(string: site) ?? URL(string: "https://livechurchnetwork.com")!) {
                factTile(icon: "🌐", label: "WEBSITE", value: "Visit website")
            }
            .buttonStyle(.plain)
        } else {
            factTile(icon: "👋", label: "STYLE", value: "Welcoming community")
        }
    }

    // MARK: - Derived

    private var locationString: String? {
        let parts = [church.city, church.state].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private var ministries: [String] {
        (church.ministries ?? "")
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var services: [ServiceTime] {
        if let s = church.serviceTimesJson, !s.isEmpty { return s }
        return ScheduleHelpers.parseLegacyServiceTimes(church.serviceTimes)
    }

    private var hasAnyExternalLink: Bool {
        [church.website, church.donationUrl, church.facebookUrl, church.instagramUrl, church.youtubeUrl]
            .compactMap { $0 }
            .contains { !$0.isEmpty }
    }

    private var hasAnything: Bool {
        let strings = [
            church.about, church.whatToExpect, church.denomination,
            locationString, church.website, church.livestreamUrl
        ]
        let anyString = strings.compactMap { $0 }.contains { !$0.isEmpty }
        return anyString || !services.isEmpty || !ministries.isEmpty
    }
}

// MARK: - Footer link

private struct FooterLink: View {
    let href: String
    let icon: String
    let label: String

    var body: some View {
        Link(destination: URL(string: href) ?? URL(string: "https://livechurchnetwork.com")!) {
            HStack(spacing: 6) {
                Text(icon).font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundColor(.lcText)
            .background(Color.white)
            .overlay(
                Capsule().stroke(Color.lcBorder, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tiny FlowLayout helper for ministries chips

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > maxW {
                totalHeight += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
            y = totalHeight + rowHeight
        }
        totalHeight = max(totalHeight, y)
        return CGSize(width: maxW.isFinite ? maxW : x, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}
