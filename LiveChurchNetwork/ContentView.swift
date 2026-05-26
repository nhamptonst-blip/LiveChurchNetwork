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
    @State private var didApplyInitialRoleTab = false
    private static var appearanceConfigured = false

    /// Profile is tab index 4 in this TabView. Church admins and platform
    /// admins land on it after sign-in (their dashboard lives there);
    /// worshippers land on the Feed (index 0).
    private static let profileTabIndex = 4

    init() {
        guard !Self.appearanceConfigured else { return }
        Self.appearanceConfigured = true
        configureNavigationBarAppearance()
        configureTabBarAppearance()
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                // Tab 0: Feed
                FeedView(selectedTab: $selectedTab)
                    .tabItem {
                        VStack(spacing: 4) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 24, weight: .semibold))
                            Text("Feed")
                                .font(.system(size: 12, weight: selectedTab == 0 ? .bold : .medium))
                        }
                    }
                    .tag(0)

                // Tab 1: Find
                DirectoryView()
                    .tabItem {
                        VStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24, weight: .semibold))
                            Text("Find")
                                .font(.system(size: 12, weight: selectedTab == 1 ? .bold : .medium))
                        }
                    }
                    .tag(1)

                // Tab 2: Live
                LiveView()
                    .tabItem {
                        VStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24, weight: .semibold))
                            Text("Live")
                                .font(.system(size: 12, weight: selectedTab == 2 ? .bold : .medium))
                        }
                    }
                    .tag(2)

                // Tab 3: Notifications
                NotificationsView()
                    .tabItem {
                        VStack(spacing: 4) {
                            Image(systemName: unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
                                .font(.system(size: 24, weight: .semibold))
                            Text("Notifications")
                                .font(.system(size: 12, weight: selectedTab == 3 ? .bold : .medium))
                        }
                    }
                    .badge(unreadCount > 0 ? unreadCount : 0)
                    .tag(3)

                // Tab 4: Profile
                if appState.profile?.role == "admin" {
                    AdminDashboardView()
                        .tabItem {
                            VStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                Text("Profile")
                                    .font(.system(size: 12, weight: selectedTab == 4 ? .bold : .medium))
                            }
                        }
                        .tag(4)
                } else if appState.profile?.role == "church_admin" {
                    ChurchAdminDashboardView()
                        .tabItem {
                            VStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                Text("Profile")
                                    .font(.system(size: 12, weight: selectedTab == 4 ? .bold : .medium))
                            }
                        }
                        .tag(4)
                } else {
                    WorkshipperDashboardView()
                        .tabItem {
                            VStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                Text("Profile")
                                    .font(.system(size: 12, weight: selectedTab == 4 ? .bold : .medium))
                            }
                        }
                        .tag(4)
                }
            }
            .tint(.lcNavy)
            .task { await loadUnreadCount() }
            .onAppear {
                if pendingTab > 0 {
                    selectedTab = pendingTab
                    pendingTab = 0
                }
            }
            // Role-aware initial routing — fires when the profile becomes
            // available and again whenever role changes (sign-out/sign-in).
            // Church admins + platform admins open straight into their
            // Profile/Dashboard tab; worshippers stay on Feed.
            // iOS 16 single-parameter onChange — the (oldValue, newValue)
            // form is iOS 17+ only.
            .onChange(of: appState.profile?.role) { newRole in
                applyInitialRoleTab(role: newRole)
            }
            .task(id: appState.profile?.role) {
                applyInitialRoleTab(role: appState.profile?.role)
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
            .padding(.bottom, 90)
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

    /// Sets the initial tab once per session based on the signed-in user's
    /// role. Skips if a `pendingTab` deep link override is in flight, and
    /// only fires once so we don't fight the user's tab choice mid-session.
    @MainActor
    private func applyInitialRoleTab(role: String?) {
        guard let role, !role.isEmpty else { return }
        guard !didApplyInitialRoleTab else { return }
        guard pendingTab == 0 else { return }   // honor deep links over default routing
        switch role {
        case "church_admin", "admin":
            selectedTab = Self.profileTabIndex
        default:
            selectedTab = 0
        }
        didApplyInitialRoleTab = true
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
            .font: UIFont.systemFont(ofSize: 34, weight: .black)
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

        // Phase 1: Navigation + Product Structure
        // Height: 78px, Background: rgba(255,255,255,0.94) with blur
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.94)

        // Top border: 1px solid rgba(31,60,136,0.08)
        let borderImage = UIImage()
        appearance.shadowImage = borderImage
        appearance.shadowColor = UIColor(red: 31/255, green: 60/255, blue: 136/255, alpha: 0.08)

        // Active item styling: #1F3C88, Font 12px, weight 700
        let activeAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(red: 31/255, green: 60/255, blue: 136/255, alpha: 1),
            .font: UIFont.systemFont(ofSize: 12, weight: .bold)
        ]

        // Inactive item styling: #6B7280, Font 12px, weight 500
        let inactiveAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1),
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]

        // Icon size: 24px (set via stacked layout)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = activeAttrs
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = inactiveAttrs
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 31/255, green: 60/255, blue: 136/255, alpha: 1)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)

        // iPad / landscape inline layout
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = activeAttrs
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = inactiveAttrs
        appearance.inlineLayoutAppearance.selected.iconColor = UIColor(red: 31/255, green: 60/255, blue: 136/255, alpha: 1)
        appearance.inlineLayoutAppearance.normal.iconColor = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(red: 31/255, green: 60/255, blue: 136/255, alpha: 1)
        UITabBar.appearance().unselectedItemTintColor = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)
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
