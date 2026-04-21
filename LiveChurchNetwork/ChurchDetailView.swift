import SwiftUI

// MARK: - Tab enum

enum ChurchProfileTab: String, CaseIterable {
    case home   = "Home"
    case about  = "About"
    case events = "Events"
    case media  = "Media"
}

// MARK: - Church Detail View

struct ChurchDetailView: View {
    let church: Church
    @EnvironmentObject var appState: AppState

    @State private var selectedTab: ChurchProfileTab

    init(church: Church, initialTab: ChurchProfileTab = .home) {
        self.church = church
        self._selectedTab = State(initialValue: initialTab)
    }

    @State private var posts: [Post] = []
    @State private var events: [Event] = []
    @State private var followerCount = 0
    @State private var isFollowing = false
    @State private var leaders: [Leader] = []
    @State private var isLoadingPosts = true
    @State private var isLoadingEvents = true
    @State private var isTogglingFollow = false
    @State private var showContact = false
    @State private var churchSubmission: ChurchSubmission?

    private var watchURL: String {
        church.website.isEmpty ? church.permalink : church.website
    }

    private var backgroundImageName: String {
        let backgroundImages = ["lcn1", "lcn2", "lcn3", "lcn4"]
        let hash = abs(church.name.hashValue % 4)
        return backgroundImages[hash]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                serviceTimesStrip
                actionStrip
                tabBar.background(Color.white)
                Divider()
                tabContent
                    .animation(.appStandard, value: selectedTab)
                    .id(selectedTab)
                    .padding(.bottom, 40)
            }
        }
        .background(Color.lcCream)
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadAll() }
        .sheet(isPresented: $showContact) {
            ChurchContactView(church: church)
                .environmentObject(appState)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Use LCN background image (same as discover card)
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFill()

                // Overlay with dark gradient for text readability
                LinearGradient(colors: [.clear, .black.opacity(0.45)],
                               startPoint: .center, endPoint: .bottom)

                if church.isLive {
                    Text("● LIVE NOW")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.red)
                        .cornerRadius(20)
                        .shadow(color: .red.opacity(0.4), radius: 6, x: 0, y: 2)
                        .padding(.top, 56)
                        .padding(.leading, 16)
                }
            }
            .frame(height: 200)
            .clipped()

            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.lcNavy)
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 80, height: 80)
                        Text(String(church.name.prefix(2)).uppercased())
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(.lcGold)
                    }
                    .offset(y: -28)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        followButton
                        Text("\(followerCount) \(followerCount == 1 ? "follower" : "followers")")
                            .font(.system(size: 11))
                            .foregroundColor(.lcText3)
                    }
                    .padding(.bottom, 10)
                }
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(church.name.isEmpty ? "Church Name" : church.name)
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.lcText)
                            .fixedSize(horizontal: false, vertical: true)
                        if church.isLive {
                            Text("LIVE")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.red)
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(Color.red.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }

                    // Denomination badge
                    Text(church.denomination.isEmpty ? "Denomination not listed" : church.denomination)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(church.denomination.isEmpty ? .lcText3 : .lcNavy)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.lcNavy.opacity(church.denomination.isEmpty ? 0.04 : 0.08))
                        .cornerRadius(20)

                    // Location
                    if !church.address.isEmpty {
                        HStack(spacing: 5) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.lcText3)
                            Text(church.address)
                                .font(.system(size: 13))
                                .foregroundColor(.lcText3)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color.white)
        }
    }

    // MARK: - Follow Button

    private var followButton: some View {
        Group {
            if appState.currentUserId == nil {
                EmptyView()
            } else {
                Button { Task { await toggleFollow() } } label: {
                    if isTogglingFollow {
                        ProgressView().frame(width: 96, height: 34).tint(.white)
                    } else {
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isFollowing ? .lcNavy : .white)
                            .frame(width: 96, height: 34)
                            .background(isFollowing ? Color.white : Color.lcNavy)
                            .cornerRadius(17)
                            .overlay(RoundedRectangle(cornerRadius: 17)
                                .stroke(Color.lcNavy, lineWidth: isFollowing ? 1.5 : 0))
                    }
                }
                .disabled(isTogglingFollow)
            }
        }
    }

    // MARK: - Service Times Strip

    private var serviceTimesStrip: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Next Service")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.lcText3)
                        .textCase(.uppercase)
                        .tracking(0.4)
                    Text(church.serviceTimes.isEmpty ? "Service time not available" : church.serviceTimes)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(church.serviceTimes.isEmpty ? .lcText3 : .lcText)
                        .lineLimit(1)
                }
                Spacer()
                if church.isLive {
                    Text("Streaming Now")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            Divider()
        }
    }

    // MARK: - Action Strip

    private var actionStrip: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    // Watch Live
                    let liveURL = church.isLive ? watchURL : ""
                    if !liveURL.isEmpty, let url = URL(string: liveURL) {
                        Link(destination: url) {
                            actionPill(icon: "play.circle.fill", label: "Watch Live", active: true, accent: true)
                        }
                    } else if !church.isLive {
                        actionPill(icon: "play.circle.fill", label: "Watch Live", active: false, accent: true)
                    }

                    // Get Directions
                    let dirTarget = church.address.isEmpty ? church.name : church.address
                    if let dirURL = mapsURL(for: dirTarget) {
                        Link(destination: dirURL) {
                            actionPill(icon: "map.fill", label: "Get Directions", active: true, accent: false)
                        }
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    // Give
                    if !church.donationUrl.isEmpty, let giveURL = URL(string: church.donationUrl) {
                        Link(destination: giveURL) {
                            actionPill(icon: "heart.fill", label: "Give", active: true, accent: false)
                        }
                    }

                    // Contact
                    if appState.currentUserId != nil {
                        Button { showContact = true } label: {
                            actionPill(icon: "envelope.fill", label: "Contact", active: true, accent: false)
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .overlay(Divider(), alignment: .bottom)
    }

    private func actionPill(icon: String, label: String, active: Bool, accent: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(label)
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundColor(!active ? .lcText3 : accent ? .white : .lcNavy)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(!active ? Color.lcBorder.opacity(0.35) : accent ? Color.red : Color.lcNavy.opacity(0.08))
        .cornerRadius(20)
        .opacity(active ? 1.0 : 0.5)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(Array(ChurchProfileTab.allCases.prefix(2)), id: \.self) { tab in
                    Button {
                        withAnimation(.appStandard) { selectedTab = tab }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .white : .lcText3)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(selectedTab == tab ? Color.lcNavy : Color.clear)
                            .cornerRadius(20)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 8) {
                ForEach(Array(ChurchProfileTab.allCases.dropFirst(2)), id: \.self) { tab in
                    Button {
                        withAnimation(.appStandard) { selectedTab = tab }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .white : .lcText3)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(selectedTab == tab ? Color.lcNavy : Color.clear)
                            .cornerRadius(20)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:   homeTab
        case .about:  aboutTab
        case .events: eventsTab
        case .media:  mediaTab
        }
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        VStack(spacing: 0) {
            // Live now banner
            if church.isLive {
                liveNowBanner
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
            }

            // Posts feed
            if isLoadingPosts {
                ProgressView().tint(.lcNavy).padding(.top, 60).frame(maxWidth: .infinity)
            } else if posts.isEmpty {
                emptyState(
                    icon: "megaphone.fill",
                    title: "No posts yet",
                    subtitle: "Share updates, services, or announcements with your community."
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(posts) { post in
                        PostCard(post: post, onLikeToggled: { updated in
                            if let idx = posts.firstIndex(where: { $0.id == updated.id }) {
                                posts[idx] = updated
                            }
                        })
                        Divider().padding(.leading, 16)
                    }
                }
                .background(Color.white)
                .padding(.top, church.isLive ? 12 : 0)
            }
        }
    }

    private var livePulsingDot: some View {
        @State var pulsing = false

        return Circle()
            .fill(Color.red)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(Color.red.opacity(0.4), lineWidth: 4)
                    .scaleEffect(pulsing ? 2.2 : 1.0)
                    .opacity(pulsing ? 0 : 1)
                    .animation(.easeOut(duration: 0.9).repeatForever(autoreverses: false), value: pulsing)
            )
            .onAppear { pulsing = true }
    }

    private var liveNowBanner: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                livePulsingDot
                Text("LIVE NOW")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.red)
                Spacer()
                if !watchURL.isEmpty, let url = URL(string: watchURL) {
                    Link(destination: url) {
                        Text("Watch →")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(20)
                    }
                }
            }
            Text("\(church.name) is currently streaming live.")
                .font(.system(size: 13))
                .foregroundColor(.lcText2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.red.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.2), lineWidth: 1))
        )
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 12) {

            infoCard(title: "About This Church") {
                if church.about.isEmpty {
                    placeholderText("This church has not added a description yet.")
                } else {
                    Text(church.about)
                        .font(.system(size: 14))
                        .foregroundColor(.lcText2)
                        .lineSpacing(5)
                }
            }

            infoCard(title: "Location & Contact") {
                VStack(spacing: 0) {
                    fieldRow(label: "Website",
                             value: church.website,
                             placeholder: "Not provided yet",
                             tapURL: church.website.isEmpty ? nil : URL(string: church.website))
                    rowDivider
                    fieldRow(label: "Address",
                             value: church.address,
                             placeholder: "Address coming soon",
                             tapURL: mapsURL(for: church.address))
                    rowDivider
                    fieldRow(label: "Phone",
                             value: church.phone,
                             placeholder: "Not provided yet",
                             tapURL: church.phone.isEmpty ? nil : URL(string: "tel:\(church.phone.filter { $0.isNumber })"))
                    rowDivider
                    fieldRow(label: "Email",
                             value: church.email,
                             placeholder: "Not provided yet",
                             tapURL: church.email.isEmpty ? nil : URL(string: "mailto:\(church.email)"))
                }
            }

            infoCard(title: "Service Info") {
                VStack(spacing: 0) {
                    fieldRow(label: "Service Times",
                             value: church.serviceTimes,
                             placeholder: "Service time not available")
                    rowDivider
                    fieldRow(label: "Denomination",
                             value: church.denomination,
                             placeholder: "Not specified")
                    rowDivider
                    fieldRow(label: "Language",
                             value: "",
                             placeholder: "Not specified")
                    rowDivider
                    fieldRow(label: "Online Services",
                             value: "",
                             placeholder: "Info coming soon")
                    rowDivider
                    fieldRow(label: "In-Person Services",
                             value: "",
                             placeholder: "Info coming soon")
                }
            }

            infoCard(title: "Online & Giving") {
                VStack(spacing: 0) {
                    if let submission = churchSubmission, let livestreamUrl = submission.livestreamUrl, !livestreamUrl.isEmpty {
                        fieldRow(label: "Livestream",
                                 value: "Watch Live",
                                 placeholder: "No livestream link",
                                 tapURL: URL(string: livestreamUrl))
                        rowDivider
                    }

                    if let submission = churchSubmission, let podcastUrl = submission.podcastUrl, !podcastUrl.isEmpty {
                        fieldRow(label: "Podcast",
                                 value: "Listen",
                                 placeholder: "No podcast link",
                                 tapURL: URL(string: podcastUrl))
                        rowDivider
                    }

                    fieldRow(label: "Donate",
                             value: church.donationUrl.isEmpty ? "" : "Donate Online",
                             placeholder: "No donation link yet",
                             tapURL: church.donationUrl.isEmpty ? nil : URL(string: church.donationUrl))
                    rowDivider
                    fieldRow(label: "LCN Page",
                             value: church.permalink.isEmpty ? "" : "View Profile",
                             placeholder: "Not listed",
                             tapURL: church.permalink.isEmpty ? nil : URL(string: church.permalink))
                }
            }

            if let submission = churchSubmission {
                if let officeHours = submission.officeHours, !officeHours.isEmpty {
                    infoCard(title: "Office Hours") {
                        Text(officeHours)
                            .font(.system(size: 14))
                            .foregroundColor(.lcText2)
                            .lineSpacing(4)
                    }
                }

                if let ministries = submission.ministries, !ministries.isEmpty {
                    infoCard(title: "Ministries") {
                        Text(ministries)
                            .font(.system(size: 14))
                            .foregroundColor(.lcText2)
                            .lineSpacing(4)
                    }
                }
            }

            leadershipCard
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Leadership Card

    private var leadershipCard: some View {
        infoCard(title: "Leadership") {
            if leaders.isEmpty {
                placeholderText("Leadership information has not been added yet.")
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(leaders.enumerated()), id: \.element.id) { idx, leader in
                        if idx > 0 { Divider() }
                        leaderRow(leader)
                    }
                }
            }
        }
    }

    private func leaderRow(_ leader: Leader) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Group {
                if let url = leader.photoUrl.flatMap({ URL(string: $0) }) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            avatarFallback(leader.name)
                        }
                    }
                } else {
                    avatarFallback(leader.name)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(leader.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.lcText)
                Text(leader.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.lcNavy)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.lcNavy.opacity(0.08))
                    .cornerRadius(20)
                if let bio = leader.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 13))
                        .foregroundColor(.lcText2)
                        .lineSpacing(4)
                        .lineLimit(4)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 12)
    }

    private func avatarFallback(_ name: String) -> some View {
        ZStack {
            Circle().fill(Color.lcNavy.opacity(0.12))
            Text(name.prefix(1).uppercased())
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.lcNavy)
        }
    }

    // MARK: - Events Tab

    private var eventsTab: some View {
        VStack(spacing: 12) {
            // Service schedule card
            if !church.serviceTimes.isEmpty {
                infoCard(title: "Regular Services") {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.lcNavy.opacity(0.6))
                        Text(church.serviceTimes)
                            .font(.system(size: 14))
                            .foregroundColor(.lcText2)
                            .lineSpacing(4)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }

            // Upcoming events
            if isLoadingEvents {
                ProgressView().tint(.lcNavy).padding(.top, 40).frame(maxWidth: .infinity)
            } else if events.isEmpty {
                emptyState(
                    icon: "calendar",
                    title: "No upcoming events",
                    subtitle: "This church hasn't added any upcoming events yet."
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("UPCOMING EVENTS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.lcText3)
                        .tracking(0.5)
                        .padding(.horizontal, 4)

                    LazyVStack(spacing: 12) {
                        ForEach(events) { event in
                            ChurchEventCard(event: event)
                        }
                    }
                }
            }
        }
        .padding(14)
    }

    // MARK: - Media Tab

    private var mediaTab: some View {
        VStack(spacing: 16) {
            if church.isLive {
                liveNowCard
            } else {
                let videoPosts = posts.filter { $0.postType == "livestream" || $0.videoUrl != nil }
                if let latest = videoPosts.first {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Latest Stream")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.lcText2)
                            .padding(.horizontal, 16)
                        PostCard(post: latest, onLikeToggled: { _ in })
                    }
                } else {
                    emptyState(
                        icon: "play.rectangle.fill",
                        title: "No media available",
                        subtitle: "Livestreams and video content will appear here."
                    )
                }
            }
        }
        .padding(.top, 16)
    }

    private var liveNowCard: some View {
        VStack(spacing: 14) {
            Text("LIVE NOW")
                .font(.system(size: 15, weight: .black))
                .foregroundColor(.red)
            Text(church.name)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.lcText)
                .multilineTextAlignment(.center)
            Text("This church is currently streaming live.")
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)

            if !watchURL.isEmpty, let url = URL(string: watchURL) {
                Link(destination: url) {
                    Text("Watch Live Stream")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.18), lineWidth: 1))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Reusable Components

    private func infoCard<Content: View>(title: String,
                                         @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lcNavy)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            Divider()

            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private func fieldRow(label: String, value: String,
                          placeholder: String, tapURL: URL? = nil) -> some View {
        let isEmpty = value.isEmpty
        let rowContent = HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.lcText3)
                .frame(width: 130, alignment: .leading)
                .fixedSize()

            Text(isEmpty ? placeholder : value)
                .font(isEmpty ? .system(size: 13).italic() : .system(size: 13))
                .foregroundColor(isEmpty ? .lcText3.opacity(0.7) : .lcText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 4)

            if tapURL != nil {
                Text("›")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.lcText3)
            }
        }
        .padding(.vertical, 11)

        return Group {
            if let url = tapURL {
                Link(destination: url) { rowContent }
            } else {
                rowContent
            }
        }
    }

    private var rowDivider: some View {
        Divider()
    }

    private func placeholderText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14).italic())
            .foregroundColor(.lcText3)
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.lcNavy.opacity(0.2))
                .padding(.top, 48)
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.lcText)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 40)
    }

    private func mapsURL(for query: String) -> URL? {
        guard !query.isEmpty,
              let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return nil }
        return URL(string: "maps://?q=\(encoded)")
    }

    // MARK: - Data Loading

    private func loadAll() async {
        async let postsTask  = SupabaseService.shared.getPostsByAuthor(authorName: church.name)
        async let eventsTask = SupabaseService.shared.getEventsByAuthor(authorName: church.name)
        async let countTask  = SupabaseService.shared.getFollowerCount(followingId: church.slug)

        var loadedPosts = (try? await postsTask) ?? []
        if let userId = appState.currentUserId {
            let liked = (try? await SupabaseService.shared.getLikedPostIds(userId: userId)) ?? []
            for i in loadedPosts.indices {
                loadedPosts[i].isLiked = liked.contains(loadedPosts[i].id)
            }
            isFollowing = (try? await SupabaseService.shared.isFollowingChurch(
                followerId: userId, churchSlug: church.slug)) ?? false
        }

        leaders = MockDataProvider.leaders(forChurch: church.name)

        // Load full church submission data
        churchSubmission = appState.church(byName: church.name)

        posts = loadedPosts.isEmpty ? MockDataProvider.posts(forChurch: church.name) : loadedPosts

        let loadedEvents = (try? await eventsTask) ?? []
        events = loadedEvents.isEmpty ? MockDataProvider.events(forChurch: church.name) : loadedEvents

        let realCount = (try? await countTask) ?? 0
        followerCount = realCount == 0 ? MockDataProvider.followerCount(forSlug: church.slug) : realCount

        isLoadingPosts = false
        isLoadingEvents = false
    }

    private func toggleFollow() async {
        guard let userId = appState.currentUserId else { return }
        isTogglingFollow = true
        do {
            if isFollowing {
                try await SupabaseService.shared.unfollow(followerId: userId, followingId: church.slug)
                isFollowing = false
                followerCount = max(0, followerCount - 1)
                HapticEngine.impact(.light)
            } else {
                try await SupabaseService.shared.follow(followerId: userId,
                                                        followingId: church.slug,
                                                        followingType: "church")
                isFollowing = true
                followerCount += 1
                HapticEngine.impact(.medium)
            }
        } catch { print("Follow error: \(error)") }
        isTogglingFollow = false
    }
}

// MARK: - Church Event Card

struct ChurchEventCard: View {
    let event: Event

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f
    }()
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d"; return f
    }()
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }()

    private var month: String { Self.monthFormatter.string(from: event.eventDate).uppercased() }
    private var day: String { Self.dayFormatter.string(from: event.eventDate) }
    private var dateString: String { Self.dateFormatter.string(from: event.eventDate) }
    private var timeString: String { Self.timeFormatter.string(from: event.eventDate) }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Text(month)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.lcGold)
                Text(day)
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(.lcNavy)
            }
            .frame(width: 44)
            .padding(.vertical, 10)

            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lcText)
                Text("\(dateString) · \(timeString)")
                    .font(.system(size: 12))
                    .foregroundColor(.lcText2)
                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                }
                if let desc = event.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
