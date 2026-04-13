import SwiftUI

// MARK: - Privacy Settings Sheet

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: Profile
    let userId: UUID
    let onSave: () -> Void

    @State private var activityPrivacy:  PrivacySetting
    @State private var followersPrivacy: PrivacySetting
    @State private var followingPrivacy: PrivacySetting
    @State private var churchesPrivacy:  PrivacySetting

    @State private var isSaving = false
    @State private var errorMessage: String?

    init(profile: Profile, userId: UUID, onSave: @escaping () -> Void) {
        self.profile = profile
        self.userId  = userId
        self.onSave  = onSave
        _activityPrivacy  = State(initialValue: profile.activityPrivacy)
        _followersPrivacy = State(initialValue: profile.followersPrivacy)
        _followingPrivacy = State(initialValue: profile.followingPrivacy)
        _churchesPrivacy  = State(initialValue: profile.churchesPrivacy)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerBanner
                    settingsCards
                        .padding(.top, 20)
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                    footerNote
                }
                .padding(.bottom, 40)
            }
            .background(Color.lcCream)
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView().tint(.lcNavy).scaleEffect(0.8)
                    } else {
                        Button("Save") { Task { await save() } }
                            .bold()
                    }
                }
            }
        }
    }

    // MARK: - Header banner

    private var headerBanner: some View {
        ZStack {
            LinearGradient(
                colors: [.lcNavy, .lcNavyDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                Text("Control your privacy")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text("Choose who can see each part of your profile.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.vertical, 28)
        }
    }

    // MARK: - Settings cards

    private var settingsCards: some View {
        VStack(spacing: 14) {
            privacyCard(
                icon: "clock.arrow.circlepath",
                title: "Activity",
                subtitle: "Follows, joins, and engagement on your profile",
                selection: $activityPrivacy
            )
            privacyCard(
                icon: "person.2.fill",
                title: "Followers",
                subtitle: "Who can see the list of people following you",
                selection: $followersPrivacy
            )
            privacyCard(
                icon: "person.badge.plus",
                title: "Following",
                subtitle: "Who can see who you follow",
                selection: $followingPrivacy
            )
            privacyCard(
                icon: "building.2.fill",
                title: "Churches",
                subtitle: "Who can see the churches you follow",
                selection: $churchesPrivacy
            )
        }
        .padding(.horizontal, 16)
    }

    private func privacyCard(icon: String, title: String, subtitle: String,
                              selection: Binding<PrivacySetting>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Row header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.lcNavy.opacity(0.09))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(.lcNavy)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.lcText)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                }
            }

            // Segmented picker
            HStack(spacing: 0) {
                ForEach(PrivacySetting.allCases, id: \.self) { option in
                    let isSelected = selection.wrappedValue == option
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selection.wrappedValue = option
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: option.icon)
                                .font(.system(size: 12))
                            Text(option.shortLabel)
                                .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                        }
                        .foregroundColor(isSelected ? .white : .lcText2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(isSelected ? Color.lcNavy : Color.clear)
                        .animation(.easeInOut(duration: 0.15), value: isSelected)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.lcNavy.opacity(0.06))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))

            // Current selection description
            HStack(spacing: 6) {
                Image(systemName: selection.wrappedValue.icon)
                    .font(.system(size: 11))
                    .foregroundColor(.lcNavy)
                Text(selectionDescription(for: selection.wrappedValue, title: title.lowercased()))
                    .font(.system(size: 12))
                    .foregroundColor(.lcText3)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private func selectionDescription(for setting: PrivacySetting, title: String) -> String {
        switch setting {
        case .public:
            return "Anyone can see your \(title)."
        case .followersOnly:
            return "Only people who follow you can see your \(title)."
        case .private:
            return "Your \(title) is hidden from everyone."
        }
    }

    // MARK: - Footer note

    private var footerNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .padding(.top, 1)
            Text("These settings only affect what others see. You always have full access to your own profile.")
                .font(.system(size: 12))
                .foregroundColor(.lcText3)
                .lineSpacing(3)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    // MARK: - Save

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await SupabaseService.shared.updatePrivacySettings(
                userId:    userId,
                activity:  activityPrivacy,
                followers: followersPrivacy,
                following: followingPrivacy,
                churches:  churchesPrivacy
            )
            onSave()
            dismiss()
        } catch {
            errorMessage = "Could not save settings. Please try again."
        }
        isSaving = false
    }
}
