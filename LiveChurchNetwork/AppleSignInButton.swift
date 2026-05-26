import SwiftUI
import AuthenticationServices
import CryptoKit
import Supabase

// MARK: - Sign in with Apple
//
// SwiftUI wrapper around `SignInWithAppleButton` that exchanges Apple's
// identity token for a Supabase session. Required by App Store policy
// (Apple Guideline 4.8) any time the app offers another third-party
// auth provider — though here we ship it just because it's a
// dramatically faster sign-in path for the user even on its own.
//
// Setup outside the app:
//   - Apple Developer → Certificates, IDs & Profiles → Keys → create a
//     new "Sign in with Apple" key. Download the .p8 file.
//   - Apple Developer → Identifiers → register the app's Bundle ID with
//     "Sign in with Apple" capability enabled.
//   - Xcode → target → Signing & Capabilities → add "Sign in with Apple".
//   - Supabase Dashboard → Auth → Providers → Apple → paste the Service
//     ID, Team ID, Key ID, and the .p8 contents.

struct AppleSignInButton: View {
    let onSuccess: () -> Void
    let onError: (String) -> Void

    /// One-time random value bound to this attempt — we hash it for the
    /// Apple request and send the raw value to Supabase so the backend
    /// can verify it matches the hash inside the identity token.
    @State private var rawNonce: String = AppleSignInButton.makeNonce()

    var body: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(rawNonce)
            },
            onCompletion: { result in
                Task { await handle(result) }
            },
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 48)
        .cornerRadius(11)
    }

    @MainActor
    private func handle(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            // User cancellation isn't an error we should display.
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            onError("Couldn't complete Apple sign-in. Please try again.")

        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let idTokenData = credential.identityToken,
                  let idToken = String(data: idTokenData, encoding: .utf8) else {
                onError("Apple didn't return an identity token. Please try again.")
                return
            }
            do {
                try await SupabaseService.shared.signInWithApple(idToken: idToken, nonce: rawNonce)
                onSuccess()
                // Refresh the nonce so a retry doesn't replay the same value.
                rawNonce = AppleSignInButton.makeNonce()
            } catch {
                onError("Sign in with Apple isn't connected yet. Use email + password, or contact support.")
            }
        }
    }

    // MARK: - Nonce helpers

    private static func makeNonce(length: Int = 32) -> String {
        let chars: [Character] = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._",
        )
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        precondition(status == errSecSuccess, "Unable to generate nonce")
        return String(bytes.map { chars[Int($0) % chars.count] })
    }

    private func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
