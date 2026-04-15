import SwiftUI
import PhotosUI

// MARK: - Profile Onboarding
//
// Shown once after a new worshipper account is created.
// Steps: Profile Setup → Follow People → Done
// All steps are skippable. Follows and profile saves happen in real time.
// Completion is tracked via UserDefaults ("profileOnboarding_complete_{userId}").

struct ProfileOnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var step = 0

    // Step 0 — profile setup
    @State private var bio                     = ""
    @State private var city                    = ""
    @State private var denomination            = ""
    @State private var homeChurchSlug: String? = nil
    @State private var homeChurchName: String? = nil
    @State private var showHomeChurchPicker    = false
    @State private var isSaving                = false

    // Photo uploads
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var selectedCoverItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var coverImage: UIImage?

    // Step 1 — people follows
    @State private var followedUserIds: Set<UUID> = []

    private let totalSteps = 2   // steps 0-1; step 2 = completion

    private let suggestedPeople = Array(MockDataProvider.allSeedUsers.prefix(8))

    // Uses shared `denominationOptions` from Models.swift

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.lcCream.ignoresSafeArea()

            VStack(spacing: 0) {
                if step < totalSteps {
                    progressHeader
                }

                Group {
                    switch step {
                    case 0:  profileStep
                    case 1:  peopleStep
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
    }

    // MARK: - Progress header

    private var progressHeader: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Color.lcNavy : Color.lcNavy.opacity(0.14))
                        .frame(width: i == step ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.22), value: step)
                }
            }
            Spacer()
            Text("Step \(step + 1) of \(totalSteps)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.lcText3)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.lcBorder).frame(height: 1)
        }
    }

    // MARK: - Step 0: Profile setup

    private var profileStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                stepHeader(
                    title: "Set Up Your Profile",
                    subtitle: "Tell churches and other members a little about yourself."
                )

                // Photos (optional)
                VStack(alignment: .leading, spacing: 12) {
                    fieldLabel("PHOTOS (Optional)")

                    // Cover photo
                    photoPicker(
                        label: "📷 Cover Photo",
                        selectedItem: $selectedCoverItem,
                        image: coverImage
                    )

                    // Avatar photo
                    photoPicker(
                        label: "📷 Profile Photo",
                        selectedItem: $selectedAvatarItem,
                        image: avatarImage
                    )
                }
                .onChange(of: selectedAvatarItem) { _ in
                    Task {
                        if let data = try? await selectedAvatarItem?.loadTransferable(type: Data.self) {
                            avatarImage = UIImage(data: data)
                        }
                    }
                }
                .onChange(of: selectedCoverItem) { _ in
                    Task {
                        if let data = try? await selectedCoverItem?.loadTransferable(type: Data.self) {
                            coverImage = UIImage(data: data)
                        }
                    }
                }

                // Bio
                fieldLabel("BIO")
                bioEditor

                // City
                fieldLabel("CITY")
                TextField("e.g. Atlanta, GA", text: $city)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))

                // Denomination
                fieldLabel("DENOMINATION")
                denominationMenu

                // Home church
                fieldLabel("HOME CHURCH")
                homeChurchField

                // Optional note
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                    Text("All fields are optional. You can update them anytime from your profile.")
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Actions
                VStack(spacing: 10) {
                    if isSaving {
                        HStack { Spacer(); ProgressView().tint(.lcNavy); Spacer() }
                            .frame(height: 52)
                    } else {
                        primaryButton("Save & Continue") {
                            Task { await saveProfileAndAdvance() }
                        }
                        skipButton("Skip for now", action: advance)
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .padding(.bottom, 32)
        }
    }

    private var bioEditor: some View {
        ZStack(alignment: .topLeading) {
            if bio.isEmpty {
                Text("Share a little about your faith journey…")
                    .font(.system(size: 14))
                    .foregroundColor(.lcText3)
                    .padding(.horizontal, 14)
                    .padding(.top, 13)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $bio)
                .font(.system(size: 15))
                .foregroundColor(.lcText)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
    }

    private var denominationMenu: some View {
        Menu {
            Button("None / Not sure") { denomination = "" }
            Divider()
            ForEach(denominationOptions, id: \.self) { opt in
                Button(opt) { denomination = opt }
            }
        } label: {
            HStack {
                Text(denomination.isEmpty ? "Select denomination…" : denomination)
                    .font(.system(size: 15))
                    .foregroundColor(denomination.isEmpty ? .lcText3 : .lcText)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.lcText3)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
        }
    }

    private var homeChurchDisplayName: String? {
        if let slug = homeChurchSlug,
           let submission = appState.church(bySlug: slug) {
            return submission.churchName
        }
        if let name = homeChurchName, !name.isEmpty {
            return name
        }
        return nil
    }

    private var homeChurchField: some View {
        Button {
            showHomeChurchPicker = true
        } label: {
            HStack {
                Text(homeChurchDisplayName ?? "Pick a church (optional)")
                    .font(.system(size: 15))
                    .foregroundColor(homeChurchDisplayName == nil ? .lcText3 : .lcText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.lcText3)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
        }
        .sheet(isPresented: $showHomeChurchPicker) {
            HomeChurchPickerSheet(
                selectedSlug: $homeChurchSlug,
                customName:   $homeChurchName
            )
        }
    }

    // MARK: - Step 1: Follow people

    private var peopleStep: some View {
        VStack(spacing: 0) {
            stepHeader(
                title: "Connect with Others",
                subtitle: "Follow other members to see their reflections and activity in your feed."
            )
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(suggestedPeople) { user in
                        personRow(user)
                        if user.id != suggestedPeople.last?.id {
                            Divider().padding(.leading, 72)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            stepActions(
                followCount: followedUserIds.count,
                entityLabel: followedUserIds.count == 1 ? "person" : "people"
            )
        }
    }

    private func personRow(_ user: DiscoverableUser) -> some View {
        HStack(spacing: 12) {
            UserAvatarView(user: user, size: .small)

            VStack(alignment: .leading, spacing: 3) {
                Text(user.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lcText)
                    .lineLimit(1)
                if let d = user.denomination, !d.isEmpty {
                    Text(d)
                        .font(.system(size: 11))
                        .foregroundColor(.lcText3)
                } else if let c = user.city, !c.isEmpty {
                    Text(c)
                        .font(.system(size: 11))
                        .foregroundColor(.lcText3)
                }
            }

            Spacer()

            followToggleButton(
                isFollowed: followedUserIds.contains(user.id)
            ) {
                Task { await toggleUserFollow(user) }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Completion

    private var completionStep: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.lcTeal.opacity(0.10))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 58))
                    .foregroundColor(.lcTeal)
            }

            VStack(spacing: 14) {
                Text("You're All Set!")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.lcText)

                Text("Your feed is personalised based on the people you follow.")
                    .font(.system(size: 14))
                    .foregroundColor(.lcText3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .lineSpacing(3)
            }
            .padding(.top, 28)

            // Summary stats
            if followedUserIds.count > 0 {
                completionStat(
                    value: "\(followedUserIds.count)",
                    label: followedUserIds.count == 1 ? "Person" : "People"
                )
                .padding(.top, 32)
            }

            Spacer()
            Spacer()

            primaryButton("Go to Feed") { appState.completeProfileOnboarding() }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
    }

    private func completionStat(value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.lcNavy)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.lcText3)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Reusable components

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.lcText)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.lcText3)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.lcText3)
            .tracking(0.5)
    }

    private func followToggleButton(isFollowed: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(isFollowed ? "Following" : "Follow")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isFollowed ? .lcNavy : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isFollowed ? Color.lcNavy.opacity(0.10) : Color.lcNavy)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.14), value: isFollowed)
    }

    private func stepActions(followCount: Int, entityLabel: String) -> some View {
        VStack(spacing: 10) {
            let label = followCount > 0
                ? "Continue (\(followCount) \(entityLabel) followed)"
                : "Continue"
            primaryButton(label, action: advance)
            skipButton("Skip", action: advance)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    private func primaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.lcNavy)
                .cornerRadius(14)
        }
    }

    private func skipButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.lcText3)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
    }

    // MARK: - Navigation

    private func advance() {
        withAnimation(.easeInOut(duration: 0.28)) { step += 1 }
    }

    // MARK: - Actions

    private func saveProfileAndAdvance() async {
        guard let userId = appState.currentUserId else { advance(); return }
        isSaving = true
        let name = appState.profile?.fullName ?? ""

        // Upload photos if selected
        if let avatarImage = avatarImage, let data = avatarImage.jpegData(compressionQuality: 0.75) {
            if let photoUrl = try? await SupabaseService.shared.uploadProfileImage(
                userId: userId, data: data, bucket: "avatars") {
                try? await SupabaseService.shared.updateProfilePhotoUrl(userId: userId, photoUrl: photoUrl)
            }
        }

        if let coverImage = coverImage, let data = coverImage.jpegData(compressionQuality: 0.75) {
            if let coverUrl = try? await SupabaseService.shared.uploadProfileImage(
                userId: userId, data: data, bucket: "covers") {
                try? await SupabaseService.shared.updateProfileCoverUrl(userId: userId, coverUrl: coverUrl)
            }
        }

        try? await SupabaseService.shared.updateProfile(
            userId:         userId,
            fullName:       name,
            city:           city.trimmingCharacters(in: .whitespaces),
            denomination:   denomination,
            bio:            bio.trimmingCharacters(in: .whitespaces),
            homeChurchSlug: homeChurchSlug,
            homeChurchName: homeChurchName
        )
        // Auto-follow the home church so its posts appear in feed.
        // Only directory churches have a slug to follow — custom-name churches
        // (homeChurchName) aren't in the follow graph yet.
        // Pre-mark in followedSlugs so Step 1 shows it as already-followed.
        if let slug = homeChurchSlug {
            try? await SupabaseService.shared.follow(
                followerId: userId, followingId: slug, followingType: "church")
            followedSlugs.insert(slug)
        }
        await appState.loadProfile()
        isSaving = false
        advance()
    }

    private func toggleUserFollow(_ user: DiscoverableUser) async {
        guard let userId = appState.currentUserId else { return }
        if followedUserIds.contains(user.id) {
            followedUserIds.remove(user.id)
            try? await SupabaseService.shared.unfollow(
                followerId: userId, followingId: user.id.uuidString)
        } else {
            followedUserIds.insert(user.id)
            try? await SupabaseService.shared.follow(
                followerId: userId, followingId: user.id.uuidString, followingType: "worshipper")
        }
    }

    private func photoPicker(
        label: String,
        selectedItem: Binding<PhotosPickerItem?>,
        image: UIImage?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            PhotosPicker(selection: selectedItem, matching: .images) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: label.contains("Cover") ? 100 : 80)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    VStack(spacing: 8) {
                        Text(label)
                            .font(.system(size: 14))
                            .foregroundColor(.lcText3)
                    }
                    .frame(height: label.contains("Cover") ? 100 : 80)
                    .frame(maxWidth: .infinity)
                    .background(Color.lcBorder.opacity(0.3))
                    .cornerRadius(10)
                }
            }
        }
    }
}

// MARK: - Home Church Picker
//
// Reusable single-select church picker. Used by ProfileOnboardingView (Step 0)
// and EditWorshipperProfileView. The user can either pick a church from the
// static directory (writes `selectedSlug`) or enter a custom name for a
// church not in the directory (writes `customName`). The two are mutually
// exclusive — selecting one clears the other.

struct HomeChurchPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @Binding var selectedSlug: String?
    @Binding var customName: String?
    @State private var search = ""
    @State private var showCustomEntry = false
    @State private var customDraft = ""

    private var filtered: [Church] {
        let allChurches = appState.allChurchesForDisplay()
        guard !search.isEmpty else { return allChurches }
        let q = search.lowercased()
        return allChurches.filter {
            $0.name.lowercased().contains(q) ||
            $0.denomination.lowercased().contains(q)
        }
    }

    private var hasSelection: Bool {
        selectedSlug != nil || (customName?.isEmpty == false)
    }

    var body: some View {
        NavigationStack {
            List {
                Button {
                    customDraft = customName ?? ""
                    showCustomEntry = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.lcGold)
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("My church isn't listed")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.lcText)
                            if let name = customName, !name.isEmpty {
                                Text(name)
                                    .font(.system(size: 12))
                                    .foregroundColor(.lcNavy)
                            } else {
                                Text("Type your church name")
                                    .font(.system(size: 12))
                                    .foregroundColor(.lcText3)
                            }
                        }
                        Spacer()
                        if customName?.isEmpty == false {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.lcGold)
                                .font(.system(size: 18))
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if hasSelection {
                    Button {
                        selectedSlug = nil
                        customName = nil
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.lcText3)
                            Text("Clear home church")
                                .foregroundColor(.lcText2)
                        }
                    }
                }

                ForEach(filtered) { church in
                    Button {
                        selectedSlug = church.slug
                        customName = nil
                        dismiss()
                    } label: {
                        churchPickerRow(church)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .searchable(text: $search, prompt: "Search churches")
            .navigationTitle("Pick Your Home Church")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.lcText3)
                    }
                }
            }
            .alert("Add Your Church", isPresented: $showCustomEntry) {
                TextField("Church name", text: $customDraft)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    let trimmed = customDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    customName = trimmed
                    selectedSlug = nil
                    dismiss()
                }
            } message: {
                Text("Enter the name of the church you belong to.")
            }
        }
    }

    private func churchPickerRow(_ church: Church) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: church.image)) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default:
                    Color.lcNavy.opacity(0.09)
                        .overlay(Image(systemName: "building.2")
                            .font(.system(size: 14))
                            .foregroundColor(.lcText3))
                }
            }
            .frame(width: 46, height: 46)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(church.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lcText)
                    .lineLimit(1)
                if !church.denomination.isEmpty {
                    Text(church.denomination)
                        .font(.system(size: 11))
                        .foregroundColor(.lcText3)
                }
            }

            Spacer()

            if selectedSlug == church.slug {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.lcGold)
                    .font(.system(size: 18))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
