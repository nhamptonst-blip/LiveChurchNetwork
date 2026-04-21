import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @State private var showRegister = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.lcNavy, Color(red: 42/255, green: 79/255, blue: 168/255)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header — compact and purposeful
                VStack(spacing: 6) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

                    Text("Find Your Church")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.bottom, 14)

                // Card
                VStack(spacing: 0) {
                    if showRegister {
                        RegisterView(onSwitch: { showRegister = false })
                    } else {
                        LoginView(onSwitch: { showRegister = true })
                    }
                }
                .background(Color.white)
                .cornerRadius(16, corners: [.topLeft, .topRight])
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
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.lcText)
                .padding(.top, 20)
                .padding(.bottom, 16)

            VStack(spacing: 11) {
                AuthField(title: "Email", placeholder: "you@example.com",
                          text: $email, keyboard: .emailAddress)
                AuthField(title: "Password", placeholder: "Your password",
                          text: $password, isSecure: true, isPasswordField: true)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.top, 8)
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
                .frame(height: 48)
                .background(Color.lcGold)
                .foregroundColor(.lcText)
                .cornerRadius(11)
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .padding(.top, 12)

            VStack(spacing: 8) {
                Rectangle()
                    .fill(Color.lcBorder)
                    .frame(height: 1)

                Button {
                    onSwitch()
                } label: {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.lcText)
                        Text("Create one")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.lcNavy)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.lcNavy)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 44)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
    }

    private func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            try await SupabaseService.shared.signIn(email: email, password: password)
            HapticEngine.notification(.success)
        } catch {
            errorMessage = "Invalid email or password."
            HapticEngine.notification(.error)
        }
        isLoading = false
    }
}

// MARK: - Register

struct RegisterView: View {
    let onSwitch: () -> Void

    @EnvironmentObject var appState: AppState

    @State private var memberName  = ""
    @State private var email       = ""
    @State private var password    = ""
    @State private var isLoading   = false
    @State private var errorMessage: String?
    @State private var regChurchSlug: String? = nil
    @State private var regChurchName: String? = nil
    @State private var showChurchPicker = false

    private var formIsValid: Bool {
        !email.isEmpty && !password.isEmpty && !memberName.isEmpty
    }

    // Uses shared `denominationOptions` from Models.swift

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Title — compact
                VStack(alignment: .leading, spacing: 6) {
                    Text("Create your account")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.lcText)
                    Text("Create your profile and start discovering churches near you.")
                        .font(.system(size: 13))
                        .foregroundColor(.lcText3)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Form fields — tighter spacing
                VStack(spacing: 11) {
                    AuthField(title: "FULL NAME", placeholder: "Your name", text: $memberName)
                    AuthField(title: "EMAIL", placeholder: "you@example.com",
                              text: $email, keyboard: .emailAddress)
                    AuthField(title: "PASSWORD", placeholder: "At least 8 characters",
                              text: $password, isSecure: true, isPasswordField: true)

                    // My Church field
                    Button {
                        showChurchPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.lcText3)
                            Text(regChurchName ?? regChurchSlug ?? "My Church (optional)")
                                .font(.system(size: 16))
                                .foregroundColor(regChurchName != nil || regChurchSlug != nil ? .lcText : Color(.placeholderText))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.lcText3)
                        }
                        .padding(11)
                        .background(Color.lcCream)
                        .cornerRadius(9)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.lcBorder, lineWidth: 1))
                    }
                    .sheet(isPresented: $showChurchPicker) {
                        HomeChurchPickerSheet(
                            selectedSlug: $regChurchSlug,
                            customName: $regChurchName
                        )
                    }
                }

                // Error message — compact
                if let error = errorMessage {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .lineLimit(2)
                    }
                    .padding(.top, 10)
                }

                // CTA — less padding
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
                    .frame(height: 48)
                    .background(formIsValid ? Color.lcNavy : Color.gray.opacity(0.2))
                    .foregroundColor(formIsValid ? .white : .lcText3)
                    .cornerRadius(11)
                }
                .disabled(isLoading || !formIsValid)
                .padding(.top, 12)

                // Trust line
                Text("Join thousands of worshippers already on Live Church Network")
                    .font(.system(size: 11))
                    .foregroundColor(.lcText3)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)

                // Footer
                HStack(spacing: 2) {
                    Text("Already have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(.lcText3)
                    Button("Sign in") { onSwitch() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lcNavy)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: Sign up

    private func signUp() async {
        isLoading = true
        errorMessage = nil
        do {
            try await SupabaseService.shared.signUp(
                email: email,
                password: password,
                fullName: memberName.trimmingCharacters(in: .whitespaces),
                role: "worshipper"
            )
            // Force a profile reload now that the insert has completed — this ensures
            // checkProfileOnboarding sees the correct role and routes to the right
            // onboarding flow instead of racing with the auth signedIn event.
            await appState.loadProfile()
            // Update profile with home church if selected
            if let userId = appState.currentUserId, (regChurchSlug != nil || regChurchName != nil) {
                try? await SupabaseService.shared.updateProfile(
                    userId: userId,
                    fullName: memberName.trimmingCharacters(in: .whitespaces),
                    city: "",
                    denomination: "",
                    bio: "",
                    homeChurchSlug: regChurchSlug,
                    homeChurchName: regChurchName.map { $0.trimmingCharacters(in: .whitespaces) }
                )
            }
            HapticEngine.notification(.success)
        } catch {
            errorMessage = "Could not create account. \(error.localizedDescription)"
            HapticEngine.notification(.error)
        }
        isLoading = false
    }
}

// MARK: - Auth field

struct AuthField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isSecure = false
    var isPasswordField = false

    @State private var showPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.lcText2)
                .tracking(0.2)

            Group {
                if isSecure && isPasswordField {
                    HStack(spacing: 8) {
                        if showPassword {
                            TextField(placeholder, text: $text)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        } else {
                            SecureField(placeholder, text: $text)
                        }
                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .font(.system(size: 14))
                                .foregroundColor(.lcText3)
                        }
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.lcText)
                    .padding(11)
                    .background(Color.lcCream)
                    .cornerRadius(9)
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.lcBorder, lineWidth: 1))
                } else if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.lcText)
                        .padding(11)
                        .background(Color.lcCream)
                        .cornerRadius(9)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.lcBorder, lineWidth: 1))
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .font(.system(size: 16))
                        .foregroundColor(.lcText)
                        .padding(11)
                        .background(Color.lcCream)
                        .cornerRadius(9)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.lcBorder, lineWidth: 1))
                }
            }
        }
    }
}
