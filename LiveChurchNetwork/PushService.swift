import Foundation
import UIKit
import UserNotifications

/// Centralizes APNs registration + token submission to Supabase.
///
/// Lifecycle:
///   1. Call `requestPermissionAndRegister()` once per session after the
///      user is authenticated (NOT on cold launch — let them sign in first).
///   2. The system invokes
///        `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
///      in the AppDelegate; forward the data into `submitToken(...)`.
///   3. On sign-out, call `removeCurrentToken(...)` to drop the row.

@MainActor
final class PushService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PushService()

    /// The most-recent APNs token cached on this device. Persisted in
    /// UserDefaults so we can re-submit it after a future sign-in without
    /// re-prompting for permission.
    @AppStorageKey("apns_device_token") private var cachedToken: String?

    /// Permission state derived from the system. Updated whenever we request.
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: Registration

    /// Asks the user for permission and (if granted) kicks off APNs
    /// registration. Safe to call repeatedly.
    func requestPermissionAndRegister() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            let settings = await center.notificationSettings()
            authorizationStatus = settings.authorizationStatus
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("[PushService] permission request failed: \(error.localizedDescription)")
        }
    }

    /// Re-register without prompting (e.g. after user signs back in).
    func registerIfPreviouslyAuthorized() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        if settings.authorizationStatus == .authorized {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: Token plumbing

    /// Called from the AppDelegate when APNs returns a fresh token. Submits
    /// it to Supabase associated with the currently signed-in user.
    func submitToken(_ deviceTokenData: Data, userId: UUID?) async {
        let token = deviceTokenData.map { String(format: "%02x", $0) }.joined()
        cachedToken = token
        guard let userId else {
            // Defer until the user signs in
            return
        }
        do {
            try await SupabaseService.shared.upsertDeviceToken(
                userId: userId,
                token: token,
                platform: "ios",
                appVersion: Bundle.main.shortVersion,
                deviceModel: UIDevice.current.model,
                osVersion: UIDevice.current.systemVersion
            )
        } catch {
            print("[PushService] upsertDeviceToken failed: \(error.localizedDescription)")
        }
    }

    /// Drop the row for the current device — call on sign-out so the user
    /// stops getting pushes for an account they're no longer signed into.
    func removeCurrentToken(userId: UUID) async {
        guard let token = cachedToken else { return }
        do {
            try await SupabaseService.shared.deleteDeviceToken(userId: userId, token: token)
        } catch {
            print("[PushService] deleteDeviceToken failed: \(error.localizedDescription)")
        }
    }

    /// Re-submit the cached token after sign-in.
    func resubmitCachedToken(userId: UUID) async {
        guard let token = cachedToken else { return }
        do {
            try await SupabaseService.shared.upsertDeviceToken(
                userId: userId,
                token: token,
                platform: "ios",
                appVersion: Bundle.main.shortVersion,
                deviceModel: UIDevice.current.model,
                osVersion: UIDevice.current.systemVersion
            )
        } catch {
            print("[PushService] resubmit failed: \(error.localizedDescription)")
        }
    }

    // MARK: UNUserNotificationCenterDelegate

    /// Show banner + sound when a push arrives while the app is foregrounded.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    /// User tapped the notification — broadcast deep-link info so the root
    /// view can navigate. The userInfo keys mirror what the Edge Function
    /// puts in `data`.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let info = response.notification.request.content.userInfo
        NotificationCenter.default.post(name: .lcnPushTapped, object: nil, userInfo: info)
    }
}

extension Notification.Name {
    static let lcnPushTapped = Notification.Name("lcn.push.tapped")
}

// MARK: - Tiny Bundle helper

private extension Bundle {
    var shortVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0"
    }
}

// MARK: - @AppStorage-style backing for non-View contexts

@propertyWrapper
struct AppStorageKey<Value> {
    let key: String
    let defaults: UserDefaults
    init(_ key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }
    var wrappedValue: Value? {
        get { defaults.object(forKey: key) as? Value }
        set {
            if let newValue { defaults.set(newValue, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }
    }
}
