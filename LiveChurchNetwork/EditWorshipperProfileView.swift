import SwiftUI

struct EditWorshipperProfileView: View {
    let profile: Profile
    let userId: UUID
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var fullName: String = ""
    @State private var bio: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Full Name", systemImage: "person.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText3)

                        TextField("Your name", text: $fullName)
                            .font(.system(size: 16))
                            .padding(12)
                            .background(Color.lcCream)
                            .cornerRadius(8)
                            .textContentType(.name)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Bio", systemImage: "quote.bubble.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText3)

                        TextEditor(text: $bio)
                            .font(.system(size: 16))
                            .frame(height: 100)
                            .padding(8)
                            .background(Color.lcCream)
                            .cornerRadius(8)
                    }

                    Spacer()

                    Button {
                        Task { await savProfile() }
                    } label: {
                        Text(isSaving ? "Saving..." : "Save Changes")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.lcNavy)
                            .cornerRadius(12)
                    }
                    .disabled(isSaving)
                }
                .padding(16)
            }
            .background(Color.lcCream)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                fullName = profile.fullName ?? ""
                bio = profile.bio ?? ""
            }
        }
    }

    private func savProfile() async {
        isSaving = true
        do {
            try await SupabaseService.shared.updateProfile(
                userId: userId,
                fullName: fullName,
                city: profile.city ?? "",
                denomination: profile.denomination ?? "",
                bio: bio,
                homeChurchSlug: profile.homeChurchSlug,
                homeChurchName: profile.homeChurchName
            )
            await MainActor.run {
                onSave()
                dismiss()
            }
        } catch {
            print("Error saving profile: \(error)")
        }
        isSaving = false
    }
}
