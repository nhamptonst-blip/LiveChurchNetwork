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
            } else if appState.isAuthenticated || appState.isGuest {
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
        .animation(.easeInOut(duration: 0.3), value: appState.isGuest)
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
    private static var appearanceConfigured = false

    init() {
        guard !Self.appearanceConfigured else { return }
        Self.appearanceConfigured = true
        configureNavigationBarAppearance()
        configureTabBarAppearance()
    }

    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("Feed", systemImage: "house.fill") }

            DirectoryView()
                .tabItem { Label("Discover", systemImage: "magnifyingglass") }

            NotificationsView()
                .tabItem {
                    Label("Notifications", systemImage: unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
                }
                .badge(unreadCount > 0 ? unreadCount : 0)

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
        }
        .tint(.lcGold)
        .task { await loadUnreadCount() }
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
