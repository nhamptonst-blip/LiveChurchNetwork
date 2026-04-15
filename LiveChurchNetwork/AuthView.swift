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
                // Header — tighter and more purposeful
                VStack(spacing: 8) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .padding(.bottom, 4)

                    Text("Find Your Church.\nAnywhere.")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text("Discover communities, watch services live,\nand grow your faith.")
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

    @State private var memberName  = ""
    @State private var email       = ""
    @State private var password    = ""
    @State private var isLoading   = false
    @State private var errorMessage: String?

    private var formIsValid: Bool {
        !email.isEmpty && !password.isEmpty && !memberName.isEmpty
    }

    // Uses shared `denominationOptions` from Models.swift

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Simple title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create your account")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.lcText)
                    Text("Join the Live Church Network community.")
                        .font(.system(size: 13))
                        .foregroundColor(.lcText3)
                }
                .padding(.top, 28)
                .padding(.bottom, 24)

                // Form fields
                VStack(spacing: 14) {
                    AuthField(title: "FULL NAME", placeholder: "Your name", text: $memberName)
                    AuthField(title: "EMAIL", placeholder: "you@example.com",
                              text: $email, keyboard: .emailAddress)
                    AuthField(title: "PASSWORD", placeholder: "At least 8 characters",
                              text: $password, isSecure: true)
                }

                // Error message
                if let error = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red)
                        Text(error).font(.system(size: 13)).foregroundColor(.red)
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
        } catch {
            errorMessage = "Could not create account. \(error.localizedDescription)"
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
