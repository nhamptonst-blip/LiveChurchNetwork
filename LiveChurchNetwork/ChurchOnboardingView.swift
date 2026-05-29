import SwiftUI
import PhotosUI

// MARK: - Church Onboarding
//
// Shown once after a church_admin account is created.
// Steps: Welcome → Basic Info → Branding → Services → About & Giving → First Content → Done
// Progress is persisted so the church can resume if they leave mid-flow.
// Completion tracked via UserDefaults ("churchOnboarding_complete_{userId}").

struct ChurchOnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var step = 0
    private let totalSteps = 6   // steps 0–5; step 6 = completion

    // Step 1 — basic info
    @State private var churchName   = ""
    @State private var denomination = ""
    @State private var city         = ""
    @State private var address      = ""
    @State private var website      = ""
    @State private var phone        = ""
    @State private var churchEmail  = ""
    @State private var isSavingInfo = false

    // Step 2 — branding
    @State private var selectedLogoItem:      PhotosPickerItem?
    @State private var selectedCoverItem:     PhotosPickerItem?
    @State private var logoData:              Data?
    @State private var coverData:             Data?
    @State private var isUploadingBranding    = false

    // Step 3 — services + livestream
    @State private var serviceTimes       = ""
    @State private var offersLivestream   = false
    @State private var livestreamUrl      = ""
    @State private var isSavingServices   = false

    // Step 4 — about + contact + donation
    @State private var aboutText        = ""
    @State private var whatToExpect     = ""
    @State private var languages        = ""
    @State private var donationUrl      = ""
    @State private var isSavingAbout    = false

    // Step 5 — first content
    @State private var contentMode       = 0   // 0 = post, 1 = event
    @State private var postContent       = ""
    @State private var eventTitle        = ""
    @State private var eventDate         = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var eventLocation     = ""
    @State private var eventDescription  = ""
    @State private var isPublishing      = false

    // Cached after first save to avoid redundant Supabase fetches
    @State private var cachedSubmissionId: UUID?

    // Uses shared `denominationOptions` from Models.swift

    // Progress persistence key
    private var progressKey: String {
        "churchOnboarding_step_\(appState.currentUserId?.uuidString ?? "unknown")"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.lcCream.ignoresSafeArea()
            VStack(spacing: 0) {
                if step > 0 && step < totalSteps {
                    progressHeader
                }
                Group {
                    switch step {
                    case 0:  welcomeStep
                    case 1:  basicInfoStep
                    case 2:  brandingStep
                    case 3:  servicesStep
                    case 4:  aboutStep
                    case 5:  firstContentStep
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
        .onAppear { restoreProgress() }
        .onChange(of: step) { newStep in
            UserDefaults.standard.set(newStep, forKey: progressKey)
        }
    }

    // MARK: - Progress header

    private var progressHeader: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(1..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Color.lcNavy : Color.lcNavy.opacity(0.14))
                        .frame(width: i == step ? 22 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.22), value: step)
                }
            }
            Spacer()
            Text("Step \(step) of \(totalSteps - 1)")
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

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)

            VStack(spacing: 12) {
                Text("Welcome to\nLive Church Network")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.lcText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text("Let's set up your church so people can\ndiscover and connect with you.")
                    .font(.system(size: 15))
                    .foregroundColor(.lcText3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(3)
            }
            .padding(.top, 28)

            // What's ahead
            VStack(spacing: 0) {
                setupRow(number: "1", icon: "info.circle.fill",   label: "Add your church info & location")
                connector
                setupRow(number: "2", icon: "photo.fill",         label: "Upload your logo & cover photo")
                connector
                setupRow(number: "3", icon: "clock.fill",         label: "Set service times & livestream")
                connector
                setupRow(number: "4", icon: "doc.text.fill",      label: "Write your church description")
                connector
                setupRow(number: "5", icon: "megaphone.fill",     label: "Publish your first post or event")
            }
            .padding(.horizontal, 40)
            .padding(.top, 32)

            Spacer()
            Spacer()

            primaryButton("Set Up Your Church", action: advance)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
    }

    private func setupRow(number: String, icon: String, label: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.lcNavy).frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(.lcGold)
            }
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.lcText2)
            Spacer()
        }
    }

    private var connector: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(Color.lcNavy.opacity(0.15))
                .frame(width: 2, height: 14)
                .padding(.leading, 15)
            Spacer()
        }
    }

    // MARK: - Step 1: Basic Info

    private var basicInfoStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(
                    title: "Tell us about your church",
                    subtitle: "This is how people will find and identify your church."
                )

                // Required
                sectionLabel("REQUIRED")

                fieldGroup("CHURCH NAME") {
                    TextField("e.g. Grace Community Church", text: $churchName)
                        .styledField()
                }

                fieldGroup("DENOMINATION") {
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

                fieldGroup("CITY / LOCATION") {
                    TextField("e.g. Nashville, TN", text: $city)
                        .styledField()
                }

                // Optional
                sectionLabel("OPTIONAL — ADD NOW OR LATER")

                fieldGroup("STREET ADDRESS") {
                    TextField("e.g. 123 Main St, Nashville, TN 37201", text: $address)
                        .styledField()
                }

                fieldGroup("WEBSITE") {
                    TextField("https://yourchurch.com", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .styledField()
                }

                fieldGroup("PHONE NUMBER") {
                    TextField("e.g. (615) 555-0100", text: $phone)
                        .keyboardType(.phonePad)
                        .styledField()
                }

                fieldGroup("CHURCH EMAIL") {
                    TextField("info@yourchurch.com", text: $churchEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .styledField()
                }

                VStack(spacing: 10) {
                    if isSavingInfo {
                        loadingRow
                    } else {
                        primaryButton(churchName.trimmingCharacters(in: .whitespaces).isEmpty
                                      ? "Skip for now" : "Continue") {
                            Task { await saveBasicInfoAndAdvance() }
                        }
                        skipButton("Skip", action: advance)
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step 2: Branding

    private var brandingStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                stepHeader(
                    title: "Add your church branding",
                    subtitle: "A logo and cover photo make your profile stand out and feel real."
                )

                // Logo
                fieldGroup("CHURCH LOGO") {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.lcNavy.opacity(0.07))
                                .frame(width: 80, height: 80)
                            if let data = logoData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            } else {
                                Image(systemName: "building.2")
                                    .font(.system(size: 28))
                                    .foregroundColor(.lcNavy.opacity(0.3))
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            PhotosPicker(selection: $selectedLogoItem, matching: .images) {
                                Text(logoData == nil ? "Choose Logo" : "Change Logo")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.lcNavy)
                                    .padding(.horizontal, 18).padding(.vertical, 10)
                                    .background(Color.lcNavy.opacity(0.08))
                                    .cornerRadius(20)
                            }
                            .onChange(of: selectedLogoItem) { item in
                                Task { logoData = try? await item?.loadTransferable(type: Data.self) }
                            }
                            Text("Square image works best")
                                .font(.system(size: 11))
                                .foregroundColor(.lcText3)
                        }
                    }
                }

                // Cover
                fieldGroup("COVER PHOTO") {
                    VStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.lcNavy.opacity(0.07))
                                .frame(maxWidth: .infinity).frame(height: 130)
                            if let data = coverData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: 130)
                                    .clipped()
                                    .cornerRadius(12)
                            } else {
                                VStack(spacing: 6) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 28))
                                        .foregroundColor(.lcNavy.opacity(0.25))
                                    Text("Recommended: 1500 × 500")
                                        .font(.system(size: 11))
                                        .foregroundColor(.lcText3)
                                }
                            }
                        }
                        PhotosPicker(selection: $selectedCoverItem, matching: .images) {
                            Text(coverData == nil ? "Choose Cover Photo" : "Change Cover Photo")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.lcNavy)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(Color.lcNavy.opacity(0.08))
                                .cornerRadius(20)
                        }
                        .onChange(of: selectedCoverItem) { item in
                            Task { coverData = try? await item?.loadTransferable(type: Data.self) }
                        }
                    }
                }

                if logoData == nil && coverData == nil {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.lcNavy.opacity(0.5))
                        Text("Churches with photos get significantly more profile visits.")
                            .font(.system(size: 12))
                            .foregroundColor(.lcText3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(Color.lcNavy.opacity(0.05))
                    .cornerRadius(10)
                }

                VStack(spacing: 10) {
                    if isUploadingBranding {
                        loadingRow
                    } else {
                        primaryButton((logoData != nil || coverData != nil)
                                      ? "Upload & Continue" : "Skip for now") {
                            Task { await uploadBrandingAndAdvance() }
                        }
                        skipButton("Skip", action: advance)
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step 3: Services + Livestream

    private var servicesStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(
                    title: "Service times & livestream",
                    subtitle: "Let people know when you meet and how to tune in online."
                )

                fieldGroup("SERVICE TIMES") {
                    ZStack(alignment: .topLeading) {
                        if serviceTimes.isEmpty {
                            Text("e.g. Sundays 9:00 AM & 11:00 AM\nWednesdays 7:00 PM")
                                .font(.system(size: 14))
                                .foregroundColor(.lcText3)
                                .padding(.horizontal, 14).padding(.top, 13)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $serviceTimes)
                            .font(.system(size: 15))
                            .foregroundColor(.lcText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 90)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
                }

                Toggle(isOn: $offersLivestream) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("We livestream our services")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.lcText)
                        Text("Members can watch live from the app")
                            .font(.system(size: 12))
                            .foregroundColor(.lcText3)
                    }
                }
                .tint(.lcNavy)
                .padding(14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))

                if offersLivestream {
                    fieldGroup("LIVESTREAM URL") {
                        TextField("https://youtube.com/live/…", text: $livestreamUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .styledField()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                VStack(spacing: 10) {
                    if isSavingServices {
                        loadingRow
                    } else {
                        primaryButton("Continue") {
                            Task { await saveServicesAndAdvance() }
                        }
                        skipButton("Skip", action: advance)
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .padding(.bottom, 32)
            .animation(.easeInOut(duration: 0.22), value: offersLivestream)
        }
    }

    // MARK: - Step 4: About + Contact + Donation

    private var aboutStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(
                    title: "Complete your church profile",
                    subtitle: "Help people understand who you are and how to get involved."
                )

                // About
                sectionLabel("ABOUT YOUR CHURCH")

                fieldGroup("CHURCH DESCRIPTION") {
                    ZStack(alignment: .topLeading) {
                        if aboutText.isEmpty {
                            Text("Tell people who you are, your mission, and what makes your church community special…")
                                .font(.system(size: 14))
                                .foregroundColor(.lcText3)
                                .padding(.horizontal, 14).padding(.top, 13)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $aboutText)
                            .font(.system(size: 15))
                            .foregroundColor(.lcText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 100)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
                }

                fieldGroup("WHAT TO EXPECT") {
                    ZStack(alignment: .topLeading) {
                        if whatToExpect.isEmpty {
                            Text("e.g. Casual dress, contemporary worship, child-friendly…")
                                .font(.system(size: 14))
                                .foregroundColor(.lcText3)
                                .padding(.horizontal, 14).padding(.top, 13)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $whatToExpect)
                            .font(.system(size: 15))
                            .foregroundColor(.lcText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 70)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
                }

                fieldGroup("LANGUAGES") {
                    TextField("e.g. English, Spanish", text: $languages)
                        .styledField()
                }

                // Contact
                sectionLabel("CONTACT INFO")

                fieldGroup("PHONE") {
                    TextField("e.g. (615) 555-0100", text: $phone)
                        .keyboardType(.phonePad)
                        .styledField()
                }

                fieldGroup("EMAIL") {
                    TextField("info@yourchurch.com", text: $churchEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .styledField()
                }

                fieldGroup("WEBSITE") {
                    TextField("https://yourchurch.com", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .styledField()
                }

                // Giving
                sectionLabel("GIVING")

                fieldGroup("DONATION LINK") {
                    TextField("https://yourchurch.com/give", text: $donationUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .styledField()
                }

                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.lcNavy.opacity(0.45))
                    Text("Add a link so members can support your church online. This is optional.")
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 10) {
                    if isSavingAbout {
                        loadingRow
                    } else {
                        primaryButton("Continue") {
                            Task { await saveAboutAndAdvance() }
                        }
                        skipButton("Skip", action: advance)
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step 5: First Content

    private var firstContentStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(
                    title: "Make your church page come alive",
                    subtitle: "Add your first post or event so your page doesn't launch empty."
                )

                // Tab picker
                Picker("Content type", selection: $contentMode) {
                    Text("Write a Post").tag(0)
                    Text("Add an Event").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 4)

                if contentMode == 0 {
                    postForm
                } else {
                    eventForm
                }

                VStack(spacing: 10) {
                    if isPublishing {
                        loadingRow
                    } else {
                        let hasContent = contentMode == 0
                            ? !postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            : !eventTitle.trimmingCharacters(in: .whitespaces).isEmpty

                        if hasContent {
                            primaryButton("Finish Setup") {
                                Task { await publishContentAndAdvance() }
                            }
                        }
                        skipButton(hasContent ? "Skip publishing" : "Skip for now", action: advance)
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .padding(.bottom, 32)
            .animation(.easeInOut(duration: 0.22), value: contentMode)
        }
    }

    @ViewBuilder
    private var postForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            examplePills(
                label: "EXAMPLES",
                examples: ["Welcome message", "Weekly announcement", "Invitation to Sunday service"]
            )

            ZStack(alignment: .topLeading) {
                if postContent.isEmpty {
                    Text("Welcome everyone to our church page! We're so excited to connect with you here…")
                        .font(.system(size: 14))
                        .foregroundColor(.lcText3)
                        .padding(.horizontal, 14).padding(.top, 13)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $postContent)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 130)
                    .padding(.horizontal, 8).padding(.vertical, 4)
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
        }
    }

    @ViewBuilder
    private var eventForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            examplePills(
                label: "EXAMPLES",
                examples: ["Sunday Worship", "Youth Night", "Bible Study", "Easter Service"]
            )

            fieldGroup("EVENT NAME") {
                TextField("e.g. Sunday Morning Worship", text: $eventTitle)
                    .styledField()
            }

            fieldGroup("DATE & TIME") {
                DatePicker("", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
            }

            fieldGroup("LOCATION (OPTIONAL)") {
                TextField("e.g. Main Sanctuary or Online", text: $eventLocation)
                    .styledField()
            }

            fieldGroup("DESCRIPTION (OPTIONAL)") {
                ZStack(alignment: .topLeading) {
                    if eventDescription.isEmpty {
                        Text("A brief description of the event…")
                            .font(.system(size: 14))
                            .foregroundColor(.lcText3)
                            .padding(.horizontal, 14).padding(.top, 13)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $eventDescription)
                        .font(.system(size: 15))
                        .foregroundColor(.lcText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 80)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                }
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
            }
        }
    }

    // MARK: - Completion

    private var completionStep: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle().fill(Color.lcTeal.opacity(0.10)).frame(width: 130, height: 130)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.lcTeal)
            }

            VStack(spacing: 14) {
                Text("Your church is now live!")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.lcText)

                Text("People can now discover your church, view your profile, and engage with your content.")
                    .font(.system(size: 14))
                    .foregroundColor(.lcText3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .lineSpacing(3)
            }
            .padding(.top, 28)

            Spacer()
            Spacer()

            VStack(spacing: 12) {
                primaryButton("Go to Church Dashboard") {
                    appState.completeChurchOnboarding()
                }
                Button {
                    appState.completeChurchOnboarding()
                } label: {
                    Text("View Church Profile")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.lcNavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.lcNavy.opacity(0.07))
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
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

    private func sectionLabel(_ text: String) -> some View {
        HStack(spacing: 10) {
            Rectangle().fill(Color.lcBorder).frame(height: 1)
            Text(text)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.lcText3)
                .tracking(0.4)
                .fixedSize()
            Rectangle().fill(Color.lcBorder).frame(height: 1)
        }
        .padding(.vertical, 2)
    }

    private func fieldGroup<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lcText3)
                .tracking(0.5)
            content()
        }
    }

    private func examplePills(label: String, examples: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.lcText3)
                .tracking(0.5)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(examples, id: \.self) { ex in
                        Text(ex)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.lcNavy)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.lcNavy.opacity(0.07))
                            .cornerRadius(20)
                    }
                }
            }
        }
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

    private var loadingRow: some View {
        HStack { Spacer(); ProgressView().tint(.lcNavy); Spacer() }.frame(height: 52)
    }

    // MARK: - Progress persistence

    private func restoreProgress() {
        // Pre-fill from profile
        if churchName.isEmpty { churchName = appState.profile?.fullName ?? "" }
        if denomination.isEmpty { denomination = appState.profile?.denomination ?? "" }
        if city.isEmpty { city = appState.profile?.city ?? "" }

        // Resume saved step
        let saved = UserDefaults.standard.integer(forKey: progressKey)
        if saved > 0 && saved < totalSteps { step = saved }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.28)) { step += 1 }
    }

    // MARK: - Save: Basic Info

    private func saveBasicInfoAndAdvance() async {
        let name = churchName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let userId = appState.currentUserId else { advance(); return }
        isSavingInfo = true
        if let sub = try? await SupabaseService.shared.getOrCreateChurchSubmission(userId: userId, churchName: name) {
            cachedSubmissionId = sub.id
            try? await SupabaseService.shared.updateChurchProfile(
                submissionId: sub.id,
                churchName:   name,
                denomination: denomination,
                phone:        phone.trimmingCharacters(in: .whitespaces),
                website:      website.trimmingCharacters(in: .whitespaces),
                serviceTimes: "",
                about:        ""
            )
        }
        // Store location in profile
        try? await SupabaseService.shared.updateProfile(
            userId:         userId,
            fullName:       name,
            city:           city.trimmingCharacters(in: .whitespaces),
            denomination:   denomination,
            bio:            "",
            homeChurchSlug: nil,
            homeChurchName: nil
        )
        await appState.loadProfile()
        isSavingInfo = false
        advance()
    }

    // MARK: - Save: Branding

    private func uploadBrandingAndAdvance() async {
        guard logoData != nil || coverData != nil,
              let userId = appState.currentUserId else { advance(); return }
        isUploadingBranding = true
        // The Discover directory reads the per-church avatar_url/cover_url, so
        // write the logo/cover to the church_submissions row (by id) in
        // addition to the profile that drives the dashboard/feed avatar.
        let submissionId = (try? await SupabaseService.shared.getChurchSubmission(userId: userId))?.id
        if let data = logoData,
           let compressed = UIImage(data: data)?.jpegData(compressionQuality: 0.75) {
            if let url = try? await SupabaseService.shared.uploadProfileImage(
                userId: userId, data: compressed, bucket: "avatars") {
                try? await SupabaseService.shared.updateProfilePhotoUrl(userId: userId, photoUrl: url)
                if let sid = submissionId {
                    try? await SupabaseService.shared.updateChurchAvatarUrl(submissionId: sid, avatarUrl: url)
                }
            }
        }
        if let data = coverData,
           let compressed = UIImage(data: data)?.jpegData(compressionQuality: 0.75) {
            if let url = try? await SupabaseService.shared.uploadProfileImage(
                userId: userId, data: compressed, bucket: "covers") {
                try? await SupabaseService.shared.updateProfileCoverUrl(userId: userId, coverUrl: url)
                if let sid = submissionId {
                    try? await SupabaseService.shared.updateChurchCoverUrl(submissionId: sid, coverUrl: url)
                }
            }
        }
        await appState.loadProfile()
        isUploadingBranding = false
        advance()
    }

    // MARK: - Save: Services

    private func saveServicesAndAdvance() async {
        guard let userId = appState.currentUserId else { advance(); return }
        isSavingServices = true
        let times  = serviceTimes.trimmingCharacters(in: .whitespaces)
        let stream = offersLivestream ? livestreamUrl.trimmingCharacters(in: .whitespaces) : ""
        if cachedSubmissionId == nil {
            cachedSubmissionId = (try? await SupabaseService.shared.getOrCreateChurchSubmission(
                userId: userId, churchName: appState.profile?.fullName ?? ""))?.id
        }
        if let subId = cachedSubmissionId {
            let aboutValue = stream.isEmpty ? "" : "Livestream: \(stream)"
            try? await SupabaseService.shared.updateChurchProfile(
                submissionId: subId,
                churchName:   churchName.isEmpty ? (appState.profile?.fullName ?? "") : churchName,
                denomination: denomination,
                phone:        phone,
                website:      website,
                serviceTimes: times,
                about:        aboutValue
            )
        }
        isSavingServices = false
        advance()
    }

    // MARK: - Save: About + Contact + Donation

    private func saveAboutAndAdvance() async {
        guard let userId = appState.currentUserId else { advance(); return }
        isSavingAbout = true
        let about = buildAboutText()
        if cachedSubmissionId == nil {
            cachedSubmissionId = (try? await SupabaseService.shared.getOrCreateChurchSubmission(
                userId: userId, churchName: appState.profile?.fullName ?? ""))?.id
        }
        if let subId = cachedSubmissionId {
            try? await SupabaseService.shared.updateChurchProfile(
                submissionId: subId,
                churchName:   churchName.isEmpty ? (appState.profile?.fullName ?? "") : churchName,
                denomination: denomination,
                phone:        phone,
                website:      website,
                serviceTimes: serviceTimes,
                about:        about
            )
        }
        isSavingAbout = false
        advance()
    }

    private func buildAboutText() -> String {
        var parts: [String] = []
        let desc = aboutText.trimmingCharacters(in: .whitespacesAndNewlines)
        let expect = whatToExpect.trimmingCharacters(in: .whitespacesAndNewlines)
        let langs = languages.trimmingCharacters(in: .whitespaces)
        let donation = donationUrl.trimmingCharacters(in: .whitespaces)
        if !desc.isEmpty    { parts.append(desc) }
        if !expect.isEmpty  { parts.append("What to expect: \(expect)") }
        if !langs.isEmpty   { parts.append("Languages: \(langs)") }
        if !donation.isEmpty { parts.append("Donate: \(donation)") }
        return parts.joined(separator: "\n\n")
    }

    // MARK: - Publish: First Content

    private func publishContentAndAdvance() async {
        guard let userId = appState.currentUserId,
              let profile = appState.profile else { advance(); return }
        isPublishing = true
        let name = profile.fullName ?? churchName
        if contentMode == 0 {
            let content = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                try? await SupabaseService.shared.createPost(
                    authorId:   userId,
                    authorName: name,
                    authorType: "church",
                    content:    content,
                    photoUrl:   nil,
                    videoUrl:   nil,
                    postType:   "update"
                )
            }
        } else {
            let title = eventTitle.trimmingCharacters(in: .whitespaces)
            if !title.isEmpty {
                try? await SupabaseService.shared.createEvent(
                    authorId:    userId,
                    authorName:  name,
                    title:       title,
                    description: eventDescription.isEmpty ? nil : eventDescription,
                    eventDate:   eventDate,
                    location:    eventLocation.isEmpty ? nil : eventLocation
                )
            }
        }
        isPublishing = false
        advance()
    }
}

// MARK: - TextField style helper

extension View {
    func styledField() -> some View {
        self
            .font(.system(size: 15))
            .foregroundColor(.lcText)
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lcBorder, lineWidth: 1))
    }
}
