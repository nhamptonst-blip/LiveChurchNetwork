import SwiftUI
import PhotosUI
import Supabase
import Storage

struct ProfileOnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var step = 0
    private let totalSteps = 2  // steps 0-2; step 3 = completion

    // Step 0 — profile info
    @State private var city = ""
    @State private var denomination = ""
    @State private var bio = ""
    @State private var profilePhotoItem: PhotosPickerItem?
    @State private var profilePhotoData: Data?
    @State private var coverPhotoItem: PhotosPickerItem?
    @State private var coverPhotoData: Data?

    // Step 1 — follow churches
    @State private var selectedChurches: Set<String> = []
    @State private var churchesToShow: [Church] = []

    // Step 2 — follow people
    @State private var selectedPeople: Set<UUID> = []
    @State private var peoplesToShow: [DiscoverableUser] = []

    @State private var isLoading = false
    @State private var isSaving = false

    var body: some View {
        ZStack {
            Color.lcCream.ignoresSafeArea()
            VStack(spacing: 0) {
                if step > 0 && step < 3 {
                    progressHeader
                }
                Group {
                    switch step {
                    case 0:  profileStep
                    case 1:  followChurchesStep
                    case 2:  followPeopleStep
                    default: completionStep
                    }
                }
                .id(step)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .animation(.easeInOut(duration: 0.28), value: step)
        }
        .task { await loadChurchesAndPeople() }
    }

    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i < step ? Color.lcGold : Color.lcBorder)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 16)

            HStack {
                Button { if step > 0 { step -= 1 } } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.lcNavy)
                }
                Spacer()
                Text("Step \(step + 1) of 3")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText3)
                Spacer()
                Button { if step < 2 { step += 1 } } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.lcNavy)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .border(Color.lcBorder, width: 1)
    }

    private var profileStep: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Complete Your Profile")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.lcText)
                        Text("Tell us a bit about yourself")
                            .font(.system(size: 14))
                            .foregroundColor(.lcText2)
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

                    // City
                    VStack(alignment: .leading, spacing: 8) {
                        Text("City")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText3)
                        TextField("Your city", text: $city)
                            .font(.system(size: 16))
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .border(Color.lcBorder, width: 1)
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

                    Button {
                        step += 1
                    } label: {
                        Text("Next")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.lcNavy)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 24)
            }
            .background(Color.lcCream)
        }
    }

    private var followChurchesStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Follow Churches")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.lcText)
                    Text("Start by following your local churches")
                        .font(.system(size: 14))
                        .foregroundColor(.lcText2)
                }
                .padding(.horizontal, 16)

                VStack(spacing: 12) {
                    ForEach(churchesToShow.prefix(10), id: \.slug) { church in
                        Button(action: {
                            if selectedChurches.contains(church.slug) {
                                selectedChurches.remove(church.slug)
                            } else {
                                selectedChurches.insert(church.slug)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: selectedChurches.contains(church.slug) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(selectedChurches.contains(church.slug) ? .lcGold : .lcText3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(church.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.lcText)
                                    Text(church.denomination)
                                        .font(.system(size: 12))
                                        .foregroundColor(.lcText3)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                Button {
                    Task { await followSelectedChurches() }
                    step += 1
                } label: {
                    Text("Continue")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.lcNavy)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 24)
        }
        .background(Color.lcCream)
    }

    private var followPeopleStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Follow People")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.lcText)
                    Text("Connect with other worshippers")
                        .font(.system(size: 14))
                        .foregroundColor(.lcText2)
                }
                .padding(.horizontal, 16)

                VStack(spacing: 12) {
                    ForEach(peoplesToShow.prefix(8), id: \.id) { person in
                        Button(action: {
                            if selectedPeople.contains(person.id) {
                                selectedPeople.remove(person.id)
                            } else {
                                selectedPeople.insert(person.id)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: selectedPeople.contains(person.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(selectedPeople.contains(person.id) ? .lcGold : .lcText3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(person.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.lcText)
                                    Text(person.city ?? person.denomination ?? "Member")
                                        .font(.system(size: 12))
                                        .foregroundColor(.lcText3)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                Button {
                    Task { await finishOnboarding() }
                } label: {
                    Text(isSaving ? "Finishing..." : "Complete")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isSaving ? Color.gray : Color.lcNavy)
                        .cornerRadius(8)
                        .disabled(isSaving)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 24)
        }
        .background(Color.lcCream)
    }

    private var completionStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.lcGold)

            VStack(spacing: 12) {
                Text("Welcome!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.lcText)
                Text("Your profile is ready. Start exploring churches and connecting with the community.")
                    .font(.system(size: 15))
                    .foregroundColor(.lcText2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                appState.completeProfileOnboarding()
            } label: {
                Text("Go to Feed")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.lcNavy)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.vertical, 40)
        .background(Color.lcCream)
    }

    private func loadChurchesAndPeople() async {
        churchesToShow = appState.allChurchesForDisplay()
        do {
            peoplesToShow = (try? await SupabaseService.shared.getDiscoverableWorshippers().map { profile in
                DiscoverableUser(
                    id: profile.id,
                    name: profile.fullName ?? "User",
                    bio: profile.bio,
                    denomination: profile.denomination,
                    city: profile.city,
                    photoUrl: profile.photoUrl
                )
            }) ?? []
        } catch {
            print("Error loading people: \(error)")
        }
    }

    private func followSelectedChurches() async {
        guard let userId = appState.currentUserId else { return }
        for churchSlug in selectedChurches {
            try? await SupabaseService.shared.follow(
                followerId: userId,
                followingId: churchSlug,
                followingType: "church"
            )
        }
    }

    private func finishOnboarding() async {
        isSaving = true
        guard let userId = appState.currentUserId else { return }

        do {
            // Upload profile photo if selected
            if let profileData = profilePhotoData {
                let photoUrl = try await SupabaseService.shared.uploadProfileImage(userId: userId, data: profileData, bucket: "avatars")
                try await SupabaseService.shared.updateProfilePhotoUrl(userId: userId, photoUrl: photoUrl)
            }

            // Update profile details
            try await SupabaseService.shared.updateProfile(
                userId: userId,
                fullName: appState.profile?.fullName ?? "",
                city: city,
                denomination: denomination,
                bio: bio,
                homeChurchSlug: appState.profile?.homeChurchSlug,
                homeChurchName: appState.profile?.homeChurchName
            )

            // Follow selected people
            for personId in selectedPeople {
                try? await SupabaseService.shared.follow(
                    followerId: userId,
                    followingId: personId.uuidString,
                    followingType: "worshipper"
                )
            }

            await MainActor.run {
                appState.completeProfileOnboarding()
            }
        } catch {
            print("Error completing onboarding: \(error)")
        }
        isSaving = false
    }
}


