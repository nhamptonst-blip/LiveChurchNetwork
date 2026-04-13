import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var liveChurches: [ChurchSubmission] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    HeroSection(churchCount: churchCount)
                    mainContent
                }
            }
            .background(Color.lcCream)
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
        }
        .task { await loadLive() }
    }

    private var featuredChurches: [Church] {
        appState.allChurchesForDisplay().prefix(6).map { $0 }
    }

    private var churchCount: Int {
        appState.approvedChurches.count
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            if !liveChurches.isEmpty {
                liveSection
            }
            featuredSection
        }
        .padding(.vertical, 28)
    }

    // MARK: Live section

    private var liveSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Live Now", subtitle: "\(liveChurches.count) streaming")
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(liveChurches) { submission in
                        LiveChurchCard(submission: submission)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: Featured section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Browse Churches", subtitle: "\(churchCount) churches listed")
                .padding(.horizontal, 20)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(featuredChurches) { church in
                    ChurchCard(church: church)
                }
            }
            .padding(.horizontal, 20)

            NavigationLink(destination: DirectoryView()) {
                Text("View all \(churchCount) churches →")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lcNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.lcNavy.opacity(0.06))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
            }
        }
    }

    private func loadLive() async {
        do {
            liveChurches = try await SupabaseService.shared.getLiveChurches()
        } catch {
            print("Live load error: \(error)")
        }
    }
}

// MARK: - Hero

struct HeroSection: View {
    let churchCount: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [.lcNavy, Color(red: 42/255, green: 79/255, blue: 168/255)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 260)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .cornerRadius(8)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Live Church Network")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("Bringing Churches and People Together")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
                .padding(.bottom, 12)

                Text("Find Your\nChurch Home")
                    .font(.system(size: 30, weight: .black))
                    .foregroundColor(.white)
                    .lineSpacing(2)

                Text("Discover \(churchCount)+ churches streaming worldwide.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }
}

// MARK: - Live church card (horizontal scroll)

struct LiveChurchCard: View {
    let submission: ChurchSubmission

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.lcNavy.opacity(0.08))
                    .frame(width: 160, height: 100)
                    .overlay(Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.title2).foregroundColor(.lcNavy.opacity(0.3)))

                LiveBadge().padding(8)
            }

            Text(submission.churchName ?? "Church")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.lcText)
                .lineLimit(2)
                .frame(width: 160, alignment: .leading)

            if let denom = submission.denomination, !denom.isEmpty {
                Text(denom)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.lcNavy)
            }
        }
        .frame(width: 160)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.lcText)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.lcText3)
            }
            Spacer()
        }
    }
}
