import SwiftUI
import PhotosUI
import Supabase
import Storage

struct ProfileOnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var denomination = ""
    @State private var bio = ""
    @State private var profilePhotoItem: PhotosPickerItem?
    @State private var profilePhotoData: Data?
    @State private var coverPhotoItem: PhotosPickerItem?
    @State private var coverPhotoData: Data?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Complete Your Profile")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.lcText)
                        Text("Just a few more details")
                            .font(.system(size: 14))
                            .foregroundColor(.lcText2)
                    }
                    .padding(.horizontal, 16)

                    // Cover Photo
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cover Photo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText3)
                        PhotosPicker(selection: $coverPhotoItem, matching: .images) {
                            ZStack {
                                if let coverData = coverPhotoData, let uiImage = UIImage(data: coverData) {
                                    Image(uiImage: uiImage)
                                        .resizable().scaledToFill()
                                } else {
                                    LinearGradient(colors: [.lcNavy, .lcNavyDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                                }
                                VStack(spacing: 4) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                    Text("Tap to choose")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 120)
                            .cornerRadius(8)
                        }
                        .onChange(of: coverPhotoItem) { item in
                            Task {
                                coverPhotoData = try? await item?.loadTransferable(type: Data.self)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Profile Photo
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile Photo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText3)
                        PhotosPicker(selection: $profilePhotoItem, matching: .images) {
                            ZStack {
                                if let profileData = profilePhotoData, let uiImage = UIImage(data: profileData) {
                                    Image(uiImage: uiImage)
                                        .resizable().scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.lcNavy)
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            VStack(spacing: 4) {
                                                Image(systemName: "photo.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white)
                                                Text("Add Photo")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white)
                                            }
                                        )
                                }
                            }
                        }
                        .onChange(of: profilePhotoItem) { item in
                            Task {
                                profilePhotoData = try? await item?.loadTransferable(type: Data.self)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Denomination
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Denomination")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText3)
                        Menu {
                            Button("None") { denomination = "" }
                            ForEach(denominationOptions, id: \.self) { denom in
                                Button(denom) { denomination = denom }
                            }
                        } label: {
                            HStack {
                                Text(denomination.isEmpty ? "Select denomination..." : denomination)
                                    .foregroundColor(denomination.isEmpty ? .lcText3 : .lcText)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.lcText3)
                            }
                            .font(.system(size: 16))
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .border(Color.lcBorder, width: 1)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Bio
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio (Optional)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText3)
                        TextEditor(text: $bio)
                            .font(.system(size: 16))
                            .frame(height: 100)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(8)
                            .border(Color.lcBorder, width: 1)
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    // Finish button
                    Button {
                        Task { await finishOnboarding() }
                    } label: {
                        Text(isLoading ? "Completing..." : "Finish Setup")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(isLoading ? Color.gray : Color.lcNavy)
                            .cornerRadius(8)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 24)
            }
            .background(Color.lcCream)
        }
    }

    private func finishOnboarding() async {
        isLoading = true
        guard let userId = appState.currentUserId else { return }

        do {
            // Upload profile photo if selected
            if let profileData = profilePhotoData {
                let photoUrl = try await SupabaseService.shared.uploadProfileImage(userId: userId, data: profileData, bucket: "avatars")
                try await SupabaseService.shared.updateProfilePhotoUrl(userId: userId, photoUrl: photoUrl)
            }

            // Upload cover photo if selected
            if let coverData = coverPhotoData {
                let coverUrl = try await SupabaseService.shared.uploadProfileImage(userId: userId, data: coverData, bucket: "covers")
                try await SupabaseService.shared.updateProfileCoverUrl(userId: userId, coverUrl: coverUrl)
            }

            // Update profile details
            try await SupabaseService.shared.updateProfile(
                userId: userId,
                fullName: appState.profile?.fullName ?? "",
                city: appState.profile?.city ?? "",
                denomination: denomination,
                bio: bio,
                homeChurchSlug: appState.profile?.homeChurchSlug ?? "",
                homeChurchName: appState.profile?.homeChurchName ?? ""
            )

            await MainActor.run {
                appState.completeProfileOnboarding()
            }
        } catch {
            print("Error completing onboarding: \(error)")
        }
        isLoading = false
    }
}


