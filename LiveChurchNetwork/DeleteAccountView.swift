import SwiftUI

// MARK: - Delete Account
//
// Type-to-confirm destructive flow that calls the `delete-account` Edge
// Function. Required by App Store Guideline 5.1.1(v).
//
// Linked from:
//   - Worshipper dashboard (Profile tab → Privacy section)
//   - Church admin dashboard kebab menu
//
// Mirrors the web `<DeleteAccountSection>` so members get an identical
// experience whichever surface they use to remove their account.

struct DeleteAccountView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var confirmText = ""
    @State private var busy = false
    @State private var errorMessage: String?

    private static let confirmPhrase = "delete"

    private var canConfirm: Bool {
        confirmText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            == Self.confirmPhrase && !busy
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                // What gets deleted — explicit list so the user is never
                // surprised by what's gone after the action completes.
                deletionList

                Text("We can't restore an account after deletion. This action is irreversible.")
                    .font(.system(size: 12))
                    .foregroundColor(.lcText3)

                confirmField

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }

                deleteButton
            }
            .padding(20)
        }
        .background(Color.lcCream)
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") { dismiss() }.disabled(busy)
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Delete account")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.red)
            Text("Permanently delete your account and everything it owns.")
                .font(.system(size: 14))
                .foregroundColor(.lcText2)
        }
    }

    private var deletionList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This permanently deletes:")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.lcText)
            VStack(alignment: .leading, spacing: 6) {
                bullet("Your profile, photo, bio, and privacy settings")
                bullet("Every post, comment, prayer response, and inquiry you've sent")
                bullet("Every follow, block, hidden post, and saved church")
                bullet("Your notification history and device push tokens")
                if appState.profile?.role == "church_admin" {
                    bullet("Your church listing, posts, events, and member inquiries")
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").foregroundColor(.lcText3)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.lcText2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var confirmField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("TYPE")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.lcText3)
                Text(Self.confirmPhrase)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
                Text("TO CONFIRM")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.lcText3)
            }
            TextField(Self.confirmPhrase, text: $confirmText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .font(.system(size: 15))
                .padding(12)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.4), lineWidth: 1)
                )
                .cornerRadius(12)
        }
    }

    private var deleteButton: some View {
        Button {
            Task { await performDelete() }
        } label: {
            HStack {
                if busy {
                    ProgressView().tint(.white)
                } else {
                    Text("Delete forever")
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(canConfirm ? Color.red : Color.red.opacity(0.4))
            .cornerRadius(12)
        }
        .disabled(!canConfirm)
    }

    // MARK: - Action

    private func performDelete() async {
        busy = true
        errorMessage = nil
        do {
            try await SupabaseService.shared.deleteCurrentAccount()
            // signOut already happened inside the service; AppState's auth
            // listener will route back to the login screen automatically.
            HapticEngine.notification(.success)
            await MainActor.run { dismiss() }
        } catch {
            HapticEngine.notification(.error)
            errorMessage = error.localizedDescription.isEmpty
                ? "Couldn't delete your account. Please try again."
                : error.localizedDescription
        }
        busy = false
    }
}
