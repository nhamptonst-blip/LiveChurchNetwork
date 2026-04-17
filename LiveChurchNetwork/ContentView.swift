import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                SplashView()
            } else if appState.isAuthenticated && appState.needsChurchOnboarding {
                ChurchOnboardingView()
            } else if appState.isAuthenticated && appState.needsProfileOnboarding {
                ProfileOnboardingView()
            } else if appState.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        // The brand uses near-black text (#161616) on cream/white backgrounds.
        // Force light appearance app-wide so system controls (Form, List, sheets)
        // don't render dark backgrounds underneath our explicit colors.
        .preferredColorScheme(.light)
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appState.isLoading)
        .animation(.easeInOut(duration: 0.3), value: appState.needsProfileOnboarding)
        .animation(.easeInOut(duration: 0.3), value: appState.needsChurchOnboarding)
    }
}

// MARK: - Splash

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.lcNavy, .lcNavyDark],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(16)
                Text("Live Church Network")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Bringing Churches and People Together")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                ProgressView()
                    .tint(.lcGold)
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Main tab bar

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var unreadCount = 0
    @State private var selectedTab = 0
    @AppStorage("pendingNavigationTab") private var pendingTab = 0
    @State private var showFeedback = false
    private static var appearanceConfigured = false

    init() {
        guard !Self.appearanceConfigured else { return }
        Self.appearanceConfigured = true
        configureNavigationBarAppearance()
        configureTabBarAppearance()
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                FeedView()
                    .tabItem { Label("Feed", systemImage: "house.fill") }
                    .tag(0)

                DirectoryView()
                    .tabItem { Label("Discover", systemImage: "magnifyingglass") }
                    .tag(1)

                NotificationsView()
                    .tabItem {
                        Label("Notifications", systemImage: unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
                    }
                    .badge(unreadCount > 0 ? unreadCount : 0)
                    .tag(2)

                Group {
                    if appState.profile?.role == "admin" {
                        AdminDashboardView()
                    } else if appState.profile?.role == "church_admin" {
                        ChurchAdminDashboardView()
                    } else {
                        WorkshipperDashboardView()
                    }
                }
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(3)
            }
            .tint(.lcGold)
            .task { await loadUnreadCount() }
            .onAppear {
                if pendingTab > 0 {
                    selectedTab = pendingTab
                    pendingTab = 0
                }
            }

            // Feedback FAB
            Button {
                showFeedback = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Feedback")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.lcNavy.opacity(0.85))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 65)
        }
        .sheet(isPresented: $showFeedback) {
            FeedbackSheet()
        }
    }

    private func loadUnreadCount() async {
        guard let userId = appState.currentUserId else { return }
        let notifs = (try? await SupabaseService.shared.getNotifications(userId: userId)) ?? []
        unreadCount = notifs.filter { !$0.isRead }.count
    }

    // MARK: - Navigation bar

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = UIColor(red: 226/255, green: 222/255, blue: 216/255, alpha: 1) // lcBorder

        // Large title — dark charcoal, heavy weight
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.lcText,
            .font: UIFont.systemFont(ofSize: 32, weight: .black)
        ]

        // Inline title
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.lcText,
            .font: UIFont.systemFont(ofSize: 17, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance  = appearance
        UINavigationBar.appearance().compactAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: - Tab bar

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.backgroundEffect = nil   // disable any translucent material so content can't bleed through

        // Top border shadow
        appearance.shadowColor = UIColor(red: 226/255, green: 222/255, blue: 216/255, alpha: 1)

        // Active item — gold + heavy weight for unmistakable selection
        let activeAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.lcGold,
            .font: UIFont.systemFont(ofSize: 10, weight: .heavy)
        ]
        // Inactive item — muted gray
        let inactiveAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.lcText3,
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]

        appearance.stackedLayoutAppearance.selected.titleTextAttributes    = activeAttrs
        appearance.stackedLayoutAppearance.normal.titleTextAttributes      = inactiveAttrs
        appearance.stackedLayoutAppearance.selected.iconColor              = .lcGold
        appearance.stackedLayoutAppearance.normal.iconColor                = .lcText3

        // iPad / landscape inline layout — same treatment
        appearance.inlineLayoutAppearance.selected.titleTextAttributes     = activeAttrs
        appearance.inlineLayoutAppearance.normal.titleTextAttributes       = inactiveAttrs
        appearance.inlineLayoutAppearance.selected.iconColor               = .lcGold
        appearance.inlineLayoutAppearance.normal.iconColor                 = .lcText3

        UITabBar.appearance().standardAppearance      = appearance
        UITabBar.appearance().scrollEdgeAppearance    = appearance
        UITabBar.appearance().tintColor               = .lcGold
        UITabBar.appearance().unselectedItemTintColor = .lcText3
    }
}

// MARK: - Feedback Sheet

struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var category = "General"
    @State private var message = ""

    private let categories = ["General", "Bug Report", "Feature Request", "Praise"]
    private let feedbackEmail = "miked83@icloud.com"

    private var canSend: Bool { !message.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("We'd love to hear from you")
                            .font(.system(size: 15))
                            .foregroundColor(.lcText3)
                    }
                    .padding(.top, 4)

                    // Category picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CATEGORY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.lcText2)
                            .tracking(0.4)
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MESSAGE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.lcText2)
                            .tracking(0.4)
                        ZStack(alignment: .topLeading) {
                            if message.isEmpty {
                                Text("Tell us what's on your mind…")
                                    .font(.system(size: 15))
                                    .foregroundColor(.lcText3)
                                    .padding(.horizontal, 12)
                                    .padding(.top, 12)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $message)
                                .font(.system(size: 15))
                                .foregroundColor(.lcText)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 140)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }
                        .background(Color.lcCream)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
                    }

                    // Send button
                    Button {
                        sendFeedback()
                    } label: {
                        Text("Open Mail to Send")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canSend ? Color.lcNavy : Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                    .disabled(!canSend)

                    Text("Tapping the button opens your Mail app with your feedback pre-filled. Your email address will be included automatically.")
                        .font(.system(size: 11))
                        .foregroundColor(.lcText3)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(24)
            }
            .background(Color.lcCream)
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.lcNavy)
                }
            }
        }
    }

    private func sendFeedback() {
        let name = appState.profile?.fullName ?? "LCN User"
        let subject = "[\(category)] Feedback from \(name)"
        let body = message.trimmingCharacters(in: .whitespaces)

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]

        if let url = components.url {
            UIApplication.shared.open(url)
        }
        dismiss()
    }
}
