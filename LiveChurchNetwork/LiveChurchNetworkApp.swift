import SwiftUI
import UIKit

@main
struct LiveChurchNetworkApp: App {
    @StateObject private var appState = AppState()
    /// AppDelegate adaptor — required so we can hook the APNs token
    /// registration callbacks. SwiftUI alone has no equivalent surface yet.
    @UIApplicationDelegateAdaptor(LCNAppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear { delegate.appState = appState }
        }
    }
}

/// Minimal AppDelegate that exists solely to receive the APNs token from
/// `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`. The
/// rest of app lifecycle stays in SwiftUI.
final class LCNAppDelegate: NSObject, UIApplicationDelegate {
    /// Set from the WindowGroup `.onAppear` so we can pass the signed-in
    /// user's id to PushService when APNs comes back with a token.
    weak var appState: AppState?

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            await PushService.shared.submitToken(
                deviceToken,
                userId: appState?.currentUserId
            )
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[APNs] failed to register: \(error.localizedDescription)")
    }
}
