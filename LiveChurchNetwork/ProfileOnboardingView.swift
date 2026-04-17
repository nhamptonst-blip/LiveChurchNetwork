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
    @State private var roleInChurch            = ""
    @State private var selectedInterests: Set<String> = []
    @State private var showInterestsPicker     = false
    @State private var languages               = ""
    @State private var favoriteVerse           = ""
    @State private var openToPrayer            = false
    @State private var isPublicProfile         = true

    // Photo uploads
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var selectedCoverItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var coverImage: UIImage?

    // Step 1 — church follows
    @State private var followedChurchSlugs: Set<String> = []

    // Step 2 — people follows
    @State private var followedUserIds: Set<UUID> = []

    // Completion celebration
    @State private var celebrateCompletion = false

    private let totalSteps = 3   // steps 0-2; step 3 = completion

    private let suggestedPeople = Array(MockDataProvider.allSeedUsers.prefix(8))

    // Uses shared `denominationOptions` from Models.swift

    private var progressKey: String {
        "profileOnboarding_step_\(appState.currentUserId?.uuidString ?? "")"
    }

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
                    case 1:  churchesStep
                    case 2:  peopleStep
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
        .onAppear {
            let savedStep = UserDefaults.standard.integer(forKey: progressKey)
            if savedStep > 0 && savedStep < totalSteps {
                step = savedStep
            }
        }
        .onChange(of: step) { newStep in
            UserDefaults.standard.set(newStep, forKey: progressKey)
        }
    }

    // MARK: - Progress header

    private var progressHeader: some View {
        HStack {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.lcNavy)
            }
            .opacity(step > 0 ? 1 : 0)
            .disabled(step == 0)

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

                VStack(alignment: .leading, spacing: 2) {
                    Text("Set Up Your Profile")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.lcText)
                    Text("Tell churches and other members a little about yourself.")
                        .font(.system(size: 13))
                        .foregroundColor(.lcText3)
                    Text("This helps others connect with you")
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3.opacity(0.7))
                        .padding(.top, 4)
                }
                .padding(.bottom, 24)

                // Compact photo header
                VStack(spacing: 0) {
                    // Cover photo
                    ZStack(alignment: .center) {
                        if let img = coverImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                        } else {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.lcNavy.opacity(0.1), Color.lcNavy.opacity(0.05)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }

                        PhotosPicker(selection: $selectedCoverItem, matching: .images) {
                            VStack(spacing: 6) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.lcText3)
                                Text("Add Cover Photo")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.lcText3)
                            }
                            .padding(20)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 90)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lcBorder, lineWidth: 1))

                    // Spacer for avatar overlap
                    Color.clear
                        .frame(height: 50)
                }

                // Avatar circle (positioned absolutely over the cover)
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let img = avatarImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Circle().fill(Color.lcNavy.opacity(0.15))
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))

                    PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.lcNavy)
                            .clipShape(Circle())
                    }
                }
                .frame(height: 80)
                .offset(y: -40)
                .padding(.bottom, -40)
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
                VStack(alignment: .leading, spacing: 5) {
                    fieldLabel("BIO")
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 13))
                            .foregroundColor(.lcText3)
                            .frame(width: 20)
                            .padding(.top, 13)
                        bioEditor
                    }
                }

                // City
                VStack(alignment: .leading, spacing: 5) {
                    fieldLabel("CITY")
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.lcText3)
                            .frame(width: 20)
                        TextField("e.g. Atlanta, GA", text: $city)
                            .font(.system(size: 15))
                            .foregroundColor(.lcText)
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
                    }
                }

                // Denomination
                VStack(alignment: .leading, spacing: 5) {
                    fieldLabel("DENOMINATION")
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.lcText3)
                            .frame(width: 20)
                        denominationMenu
                    }
                }

                // Home church
                VStack(alignment: .leading, spacing: 5) {
                    fieldLabel("HOME CHURCH")
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.lcText3)
                            .frame(width: 20)
                        homeChurchField
                    }
                }

                // Role in Church
                VStack(alignment: .leading, spacing: 5) {
                    fieldLabel("ROLE IN CHURCH")
                    let churchRoles = ["Member", "Volunteer", "Pastor", "Worship Leader", "Youth Leader", "Small Group Leader"]
                    Menu {
                        Button("None") { roleInChurch = "" }
                        Divider()
                        ForEach(churchRoles, id: \.self) { role in
                            Button(role) { roleInChurch = role }
                        }
                    } label: {
                        HStack {
                            Text(roleInChurch.isEmpty ? "Select your role…" : roleInChurch)
                                .font(.system(size: 15))
                                .foregroundColor(roleInChurch.isEmpty ? .lcText3 : .lcText)
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

                // Interests
                VStack(alignment: .leading, spacing: 5) {
                    fieldLabel("INTERESTS")
                    Button {
                        showInterestsPicker = true
                    } label: {
                        HStack {
                            if selectedInterests.isEmpty {
                                Text("Select interests…")
                                    .font(.system(size: 15))
                                    .foregroundColor(.lcText3)
                            } else {
                                Text("\(selectedInterests.count) selected")
                                    .font(.system(size: 15))
                                    .foregroundColor(.lcText)
                            }
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
                    .sheet(isPresented: $showInterestsPicker) {
                        InterestsPickerSheet(selectedInterests: $selectedInterests, isPresented: $showInterestsPicker)
                    }
                }

                // Languages
                VStack(alignment: .leading, spacing: 5) {
                    fieldLabel("LANGUAGES SPOKEN")
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: "globe")
                            .font(.system(size: 13))
                            .foregroundColor(.lcText3)
                            .frame(width: 20)
                        TextField("e.g. English, Spanish", text: $languages)
                            .font(.system(size: 15))
                            .foregroundColor(.lcText)
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
                    }
                }

                // Favorite Verse
                VStack(alignment: .leading, spacing: 5) {
                    fieldLabel("FAVORITE VERSE")
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.lcText3)
                            .frame(width: 20)
                        TextField("e.g. John 3:16", text: $favoriteVerse)
                            .font(.system(size: 15))
                            .foregroundColor(.lcText)
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
                    }
                }

                // Prayer toggle
                Toggle(isOn: $openToPrayer) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Open to prayer requests")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.lcText)
                        Text("Others can send you prayer requests")
                            .font(.system(size: 11))
                            .foregroundColor(.lcText3)
                    }
                }
                .tint(.lcNavy)
                .padding(14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))

                // Privacy setting
                HStack {
                    Text("Profile Visibility")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lcText)
                    Spacer()
                    Picker("", selection: $isPublicProfile) {
                        Text("Public").tag(true)
                        Text("Private").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))

                // Profile preview
                VStack(alignment: .leading, spacing: 10) {
                    Text("PREVIEW")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.lcText3)
                        .tracking(0.5)

                    HStack(spacing: 12) {
                        Group {
                            if let img = avatarImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color.lcNavy.opacity(0.15)
                            }
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.lcBorder, lineWidth: 1))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(appState.profile?.fullName ?? "Your Name")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.lcText)
                            if !city.isEmpty || !denomination.isEmpty {
                                Text([city, denomination].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.system(size: 12))
                                    .foregroundColor(.lcText3)
                            }
                            if !bio.isEmpty {
                                Text(bio)
                                    .font(.system(size: 12))
                                    .foregroundColor(.lcText3)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                }

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

    // MARK: - Step 1: Follow churches

    private var churchesStep: some View {
        let suggestedChurches = appState.allChurchesForDisplay().prefix(8)
        return VStack(spacing: 0) {
            stepHeader(
                title: "Follow Churches",
                subtitle: "Discover churches and follow the ones that resonate with you."
            )
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(suggestedChurches, id: \.slug) { church in
                        churchRow(church)
                        if church.slug != suggestedChurches.last?.slug {
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
                followCount: followedChurchSlugs.count,
                entityLabel: followedChurchSlugs.count == 1 ? "church" : "churches"
            )
        }
    }

    private func churchRow(_ church: Church) -> some View {
        HStack(spacing: 12) {
            // Church image/avatar
            if !church.image.isEmpty {
                AsyncImage(url: URL(string: church.image)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                    case .empty, .failure:
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.lcText3)
                            .frame(width: 40, height: 40)
                            .background(Color.lcCream)
                            .cornerRadius(8)
                    @unknown default:
                        Color.lcCream
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                    }
                }
            } else {
                Image(systemName: "building.2.fill")
                    .foregroundColor(.lcText3)
                    .frame(width: 40, height: 40)
                    .background(Color.lcCream)
                    .cornerRadius(8)
            }

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

            followToggleButton(
                isFollowed: followedChurchSlugs.contains(church.slug)
            ) {
                Task { await toggleChurchFollow(church) }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Step 2: Follow people

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
            .scaleEffect(celebrateCompletion ? 1.0 : 0.3)
            .opacity(celebrateCompletion ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    celebrateCompletion = true
                }
            }

            VStack(spacing: 14) {
                Text("You're All Set!")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.lcText)

                Text("Your feed is personalised based on the churches and people you follow.")
                    .font(.system(size: 14))
                    .foregroundColor(.lcText3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .lineSpacing(3)
            }
            .padding(.top, 28)

            // Summary stats
            if followedChurchSlugs.count > 0 || followedUserIds.count > 0 {
                HStack(spacing: 24) {
                    if followedChurchSlugs.count > 0 {
                        completionStat(
                            value: "\(followedChurchSlugs.count)",
                            label: followedChurchSlugs.count == 1 ? "Church" : "Churches"
                        )
                    }
                    if followedUserIds.count > 0 {
                        completionStat(
                            value: "\(followedUserIds.count)",
                            label: followedUserIds.count == 1 ? "Person" : "People"
                        )
                    }
                }
                .padding(.top, 32)
            }

            Spacer()
            Spacer()

            primaryButton("Go to Feed") {
                UserDefaults.standard.removeObject(forKey: progressKey)
                appState.completeProfileOnboarding()
            }
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
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.lcText3.opacity(0.7))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
    }

    // MARK: - Navigation

    private func advance() {
        withAnimation(.easeInOut(duration: 0.28)) { step += 1 }
    }

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.28)) { step -= 1 }
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

    private func toggleChurchFollow(_ church: Church) async {
        guard let userId = appState.currentUserId else { return }
        if followedChurchSlugs.contains(church.slug) {
            followedChurchSlugs.remove(church.slug)
            try? await SupabaseService.shared.unfollow(
                followerId: userId, followingId: church.slug)
        } else {
            followedChurchSlugs.insert(church.slug)
            try? await SupabaseService.shared.follow(
                followerId: userId, followingId: church.slug, followingType: "church")
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

// MARK: - Interests Picker Sheet

struct InterestsPickerSheet: View {
    @Binding var selectedInterests: Set<String>
    @Binding var isPresented: Bool

    private let interestOptions = ["Bible Study", "Worship", "Volunteering", "Missions", "Young Adults", "Prayer", "Men's Group", "Women's Group"]

    var body: some View {
        NavigationStack {
            List {
                ForEach(interestOptions, id: \.self) { interest in
                    Button(action: {
                        if selectedInterests.contains(interest) {
                            selectedInterests.remove(interest)
                        } else {
                            selectedInterests.insert(interest)
                        }
                    }) {
                        HStack {
                            Text(interest)
                                .foregroundColor(.lcText)
                            Spacer()
                            if selectedInterests.contains(interest) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.lcNavy)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Interests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lcNavy)
                }
            }
        }
    }
}
