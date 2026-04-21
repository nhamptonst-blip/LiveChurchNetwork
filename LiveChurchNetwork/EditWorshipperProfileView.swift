import SwiftUI
import PhotosUI
import Supabase
import Storage

struct EditWorshipperProfileView: View {
    let profile: Profile
    let userId: UUID
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var fullName: String = ""
    @State private var city: String = ""
    @State private var denomination: String = ""
    @State private var bio: String = ""
    @State private var profilePhotoItem: PhotosPickerItem?
    @State private var profilePhotoData: Data?
    @State private var coverPhotoItem: PhotosPickerItem?
    @State private var coverPhotoData: Data?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Edit Your Profile")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.lcText)
                        .padding(.horizontal, 16)

                    // Cover photo
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cover Photo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText3)
                        PhotosPicker(selection: $coverPhotoItem, matching: .images) {
                            ZStack {
                                if let coverData = coverPhotoData, let uiImage = UIImage(data: coverData) {
                                    Image(uiImage: uiImage)
                                        .resizable().scaledToFill()
                                } else if let coverUrl = profile.coverUrl, let url = URL(string: coverUrl) {
                                    AsyncImage(url: url) { phase in
                                        if case .success(let img) = phase {
                                            img.resizable().scaledToFill()
                                        } else {
                                            LinearGradient(colors: [.lcNavy, .lcNavyDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        }
                                    }
                                } else {
                                    LinearGradient(colors: [.lcNavy, .lcNavyDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                                }
                                VStack(spacing: 4) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                    Text("Tap to change")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 140)
                            .cornerRadius(8)
                        }
                        .onChange(of: coverPhotoItem) { item in
                            Task {
                                coverPhotoData = try? await item?.loadTransferable(type: Data.self)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Profile photo
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile Photo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText3)
                        PhotosPicker(selection: $profilePhotoItem, matching: .images) {
                            ZStack {
                                if let profileData = profilePhotoData, let uiImage = UIImage(data: profileData) {
                                    Image(uiImage: uiImage)
                                        .resizable().scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else if let photoUrl = profile.photoUrl, let url = URL(string: photoUrl) {
                                    AsyncImage(url: url) { phase in
                                        if case .success(let img) = phase {
                                            img.resizable().scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                        } else {
                                            Circle().fill(Color.lcNavy).frame(width: 100, height: 100)
                                        }
                                    }
                                } else {
                                    Circle()
                                        .fill(Color.lcNavy)
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            VStack(spacing: 4) {
                                                Image(systemName: "photo.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.white)
                                                Text("Change")
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

                    // Full Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText3)
                        TextField("Your name", text: $fullName)
                            .font(.system(size: 16))
                            .padding(12)
                            .background(Color.lcCream)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)

                    // City
                    VStack(alignment: .leading, spacing: 8) {
                        Text("City")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText3)
                        TextField("Your city", text: $city)
                            .font(.system(size: 16))
                            .padding(12)
                            .background(Color.lcCream)
                            .cornerRadius(8)
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
                            .background(Color.lcCream)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Bio
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText3)
                        TextEditor(text: $bio)
                            .font(.system(size: 16))
                            .frame(height: 100)
                            .padding(8)
                            .background(Color.lcCream)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    // Save button
                    Button {
                        Task { await saveProfile() }
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
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 20)
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
                city = profile.city ?? ""
                denomination = profile.denomination ?? ""
                bio = profile.bio ?? ""
            }
        }
    }

    private func saveProfile() async {
        isSaving = true

        do {
            // Upload profile photo if changed
            if let profileData = profilePhotoData {
                let photoUrl = try await SupabaseService.shared.uploadProfileImage(userId: userId, data: profileData, bucket: "avatars")
                try await SupabaseService.shared.updateProfilePhotoUrl(userId: userId, photoUrl: photoUrl)
            }

            // Upload cover photo if changed
            if let coverData = coverPhotoData {
                let coverUrl = try await SupabaseService.shared.uploadProfileImage(userId: userId, data: coverData, bucket: "covers")
                try await SupabaseService.shared.updateProfileCoverUrl(userId: userId, coverUrl: coverUrl)
            }

            try await SupabaseService.shared.updateProfile(
                userId: userId,
                fullName: fullName,
                city: city,
                denomination: denomination,
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
