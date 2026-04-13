import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("preSelectedRole") private var preSelectedRole = "worshipper"
    @State private var showRegister = false

    private var isChurchRole: Bool { preSelectedRole == "church_admin" }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.lcNavy, Color(red: 42/255, green: 79/255, blue: 168/255)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header — tighter and more purposeful
                VStack(spacing: 8) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .padding(.bottom, 4)

                    Text(isChurchRole ? "Welcome to\nLive Church Network" : "Find Your Church.\nAnywhere.")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text(isChurchRole
                         ? "Set up your church and start reaching your community."
                         : "Discover communities, watch services live,\nand grow your faith.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.top, 44)
                .padding(.bottom, 28)

                // Card
                VStack(spacing: 0) {
                    if showRegister {
                        RegisterView(onSwitch: { showRegister = false })
                    } else {
                        LoginView(onSwitch: { showRegister = true })
                    }

                    if !showRegister {
                        Rectangle()
                            .fill(Color.lcBorder)
                            .frame(height: 1)
                            .padding(.horizontal, 24)

                        Button {
                            appState.continueAsGuest()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "eyes")
                                    .font(.system(size: 13))
                                    .foregroundColor(.lcText2)
                                Text("Continue as Guest")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.lcText2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                        }
                        .background(Color.white)
                    }
                }
                .background(Color.white)
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)

                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showRegister)
    }
}

// MARK: - Login

struct LoginView: View {
    let onSwitch: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Welcome back")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.lcText)
                .padding(.top, 28)
                .padding(.bottom, 20)

            VStack(spacing: 14) {
                AuthField(title: "Email", placeholder: "you@example.com",
                          text: $email, keyboard: .emailAddress)
                AuthField(title: "Password", placeholder: "Your password",
                          text: $password, isSecure: true)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }

            Button {
                Task { await signIn() }
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.lcText)
                    } else {
                        Text("Sign In")
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.lcGold)
                .foregroundColor(.lcText)
                .cornerRadius(12)
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .padding(.top, 20)

            HStack {
                Text("Don't have an account?")
                    .font(.system(size: 13))
                    .foregroundColor(.lcText3)
                Button("Create one") { onSwitch() }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcNavy)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .padding(.horizontal, 24)
    }

    private func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            try await SupabaseService.shared.signIn(email: email, password: password)
        } catch {
            errorMessage = "Invalid email or password."
        }
        isLoading = false
    }
}

// MARK: - Register

struct RegisterView: View {
    let onSwitch: () -> Void

    @EnvironmentObject var appState: AppState
    @AppStorage("preSelectedRole") private var preSelectedRole = "worshipper"

    // Shared
    @State private var role        = "worshipper"
    @State private var email       = ""
    @State private var password    = ""
    @State private var isLoading   = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    // Member-only
    @State private var memberName  = ""

    // Church-only
    @State private var churchName    = ""
    @State private var contactName   = ""
    @State private var denomination  = ""
    @State private var city          = ""

    private var isChurch: Bool { role == "church_admin" }

    private var formIsValid: Bool {
        let sharedOk = !email.isEmpty && !password.isEmpty
        if isChurch {
            return sharedOk && !churchName.isEmpty && !contactName.isEmpty
        } else {
            return sharedOk && !memberName.isEmpty
        }
    }

    // Uses shared `denominationOptions` from Models.swift

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Dynamic title
                VStack(alignment: .leading, spacing: 4) {
                    Text(isChurch ? "Create your church account" : "Create your account")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.lcText)
                    Text(isChurch
                         ? "Set up your church page and start reaching people."
                         : "Join the Live Church Network community.")
                        .font(.system(size: 13))
                        .foregroundColor(.lcText3)
                }
                .padding(.top, 28)
                .padding(.bottom, 20)
                .animation(.easeInOut(duration: 0.2), value: isChurch)

                // Account type cards
                VStack(spacing: 10) {
                    AccountTypeCard(
                        icon: "person.fill",
                        title: "I'm a Member",
                        description: "Discover churches, follow communities, and engage with your faith.",
                        selected: role == "worshipper"
                    ) { withAnimation(.easeInOut(duration: 0.22)) { role = "worshipper"; preSelectedRole = "worshipper" } }

                    AccountTypeCard(
                        icon: "building.2.fill",
                        title: "I Represent a Church",
                        description: "Create your church page, stream services, and reach people.",
                        selected: role == "church_admin"
                    ) { withAnimation(.easeInOut(duration: 0.22)) { role = "church_admin"; preSelectedRole = "church_admin" } }
                }
                .onAppear { role = "worshipper"; preSelectedRole = "worshipper" }
                .padding(.bottom, 24)

                // Dynamic form fields
                VStack(spacing: 14) {
                    if isChurch {
                        churchFields
                    } else {
                        memberFields
                    }
                }
                .animation(.easeInOut(duration: 0.22), value: isChurch)

                // Errors / success
                if let error = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red)
                        Text(error).font(.system(size: 13)).foregroundColor(.red)
                    }
                    .padding(.top, 12)
                }
                if let success = successMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text(success).font(.system(size: 13)).foregroundColor(.green)
                    }
                    .padding(.top, 12)
                }

                // CTA
                Button {
                    Task { await signUp() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Get Started")
                                .font(.system(size: 15, weight: .bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(formIsValid ? Color.lcNavy : Color.lcNavy.opacity(0.35))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading || !formIsValid)
                .padding(.top, 20)

                HStack {
                    Text("Already have an account?")
                        .font(.system(size: 13)).foregroundColor(.lcText3)
                    Button("Sign in") { onSwitch() }
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(.lcNavy)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: Member fields

    @ViewBuilder
    private var memberFields: some View {
        AuthField(title: "FULL NAME", placeholder: "Your name", text: $memberName)
        AuthField(title: "EMAIL", placeholder: "you@example.com",
                  text: $email, keyboard: .emailAddress)
        AuthField(title: "PASSWORD", placeholder: "At least 8 characters",
                  text: $password, isSecure: true)
    }

    // MARK: Church fields

    @ViewBuilder
    private var churchFields: some View {
        // Required
        sectionDivider("REQUIRED")

        AuthField(title: "CHURCH NAME", placeholder: "e.g. Grace Community Church",
                  text: $churchName)

        AuthField(title: "YOUR NAME (CHURCH CONTACT)",
                  placeholder: "The person managing this account",
                  text: $contactName)

        AuthField(title: "EMAIL", placeholder: "church@example.com",
                  text: $email, keyboard: .emailAddress)

        AuthField(title: "PASSWORD", placeholder: "At least 8 characters",
                  text: $password, isSecure: true)

        // Optional
        sectionDivider("OPTIONAL — COMPLETE NOW OR LATER")

        // Denomination picker
        VStack(alignment: .leading, spacing: 6) {
            Text("DENOMINATION")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lcText2)
                .tracking(0.3)
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
                        .foregroundColor(denomination.isEmpty ? Color(.placeholderText) : .lcText)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                }
                .padding(13)
                .background(Color.lcCream)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
        }

        AuthField(title: "CITY / LOCATION", placeholder: "e.g. Nashville, TN", text: $city)
    }

    private func sectionDivider(_ label: String) -> some View {
        HStack(spacing: 10) {
            Rectangle().fill(Color.lcBorder).frame(height: 1)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.lcText3)
                .tracking(0.4)
                .fixedSize()
            Rectangle().fill(Color.lcBorder).frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    // MARK: Sign up

    private func signUp() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            if isChurch {
                // full_name = church name (display name in app)
                // bio = contact person's name
                try await SupabaseService.shared.signUp(
                    email: email,
                    password: password,
                    fullName: churchName.trimmingCharacters(in: .whitespaces),
                    role: role,
                    bio: contactName.trimmingCharacters(in: .whitespaces),
                    city: city.isEmpty ? nil : city.trimmingCharacters(in: .whitespaces),
                    denomination: denomination.isEmpty ? nil : denomination
                )
            } else {
                try await SupabaseService.shared.signUp(
                    email: email,
                    password: password,
                    fullName: memberName.trimmingCharacters(in: .whitespaces),
                    role: role
                )
            }
            successMessage = isChurch
                ? "Church account created! Check your email to confirm."
                : "Account created! Check your email to confirm."
            // Force a profile reload now that the insert has completed — this ensures
            // checkProfileOnboarding sees the correct role and routes to the right
            // onboarding flow instead of racing with the auth signedIn event.
            await appState.loadProfile()
        } catch {
            errorMessage = "Could not create account. \(error.localizedDescription)"
        }
        isLoading = false
    }
}

// MARK: - Account type card

struct AccountTypeCard: View {
    let icon: String
    let title: String
    let description: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(selected ? Color.lcNavy : Color.lcCream)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 17))
                        .foregroundColor(selected ? .white : .lcText2)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.lcText)
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                        .lineSpacing(1.5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(selected ? .lcNavy : Color.lcBorder)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selected ? Color.lcNavy : Color.lcBorder, lineWidth: selected ? 2 : 1)
                    )
                    .shadow(color: selected ? Color.lcNavy.opacity(0.10) : Color.clear, radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: selected)
    }
}

// MARK: - Auth field

struct AuthField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.lcText2)
                .tracking(0.3)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            .font(.system(size: 15))
            .foregroundColor(.lcText)
            .padding(13)
            .background(Color.lcCream)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
        }
    }
}
