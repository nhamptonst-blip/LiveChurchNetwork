import SwiftUI

// MARK: - Church Contact View
//
// Structured inquiry form for member → church communication.
// Covers: General Question, Prayer Request, Plan a Visit,
//         Volunteer Interest, Event Question.
// Opens as a sheet from ChurchDetailView.

struct ChurchContactView: View {
    let church: Church
    let initialType: InquiryType

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: InquiryType
    @State private var subject = ""
    @State private var messageBody = ""
    @State private var isSubmitting = false
    @State private var submitted = false
    @State private var errorMessage: String?

    init(church: Church, initialType: InquiryType = .general) {
        self.church = church
        self.initialType = initialType
        self._selectedType = State(initialValue: initialType)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if submitted { successView } else { formView }
            }
            .navigationTitle(church.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.lcNavy)
                }
            }
        }
    }

    // MARK: - Form

    private var formView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Type selector ─────────────────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    Text("WHAT'S THIS ABOUT?")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.lcText3)
                        .tracking(0.5)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(InquiryType.allCases, id: \.self) { type in
                                typePill(type)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 2)
                    }
                    .padding(.horizontal, -20)
                }

                // ── Context note ──────────────────────────────────────────
                contextNote

                // ── Subject ───────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text("SUBJECT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.lcText3)
                        .tracking(0.5)
                    TextField("Brief subject line", text: $subject)
                        .font(.system(size: 15))
                        .foregroundColor(.lcText)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.lcBorder, lineWidth: 1))
                }

                // ── Message ───────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text("MESSAGE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.lcText3)
                        .tracking(0.5)
                    ZStack(alignment: .topLeading) {
                        if messageBody.isEmpty {
                            Text(selectedType.placeholder)
                                .font(.system(size: 14))
                                .foregroundColor(.lcText3)
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $messageBody)
                            .font(.system(size: 15))
                            .foregroundColor(.lcText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 140)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.lcBorder, lineWidth: 1))
                }

                // ── Sending-as label ──────────────────────────────────────
                if let name = appState.profile?.fullName, !name.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.lcText3)
                        Text("Sending as \(name)")
                            .font(.system(size: 12))
                            .foregroundColor(.lcText3)
                    }
                }

                // ── Error ─────────────────────────────────────────────────
                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }

                // ── Submit ────────────────────────────────────────────────
                Button {
                    Task { await submit() }
                } label: {
                    Group {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send Message")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canSubmit ? Color.lcNavy : Color.lcText3.opacity(0.4))
                    .cornerRadius(14)
                }
                .disabled(!canSubmit || isSubmitting)
            }
            .padding(20)
        }
        .background(Color.lcCream)
    }

    // MARK: - Type pill

    private func typePill(_ type: InquiryType) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.14)) { selectedType = type }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: type.icon)
                    .font(.system(size: 11))
                Text(type.label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(selectedType == type ? .white : .lcNavy)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(selectedType == type ? Color.lcNavy : Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.lcNavy.opacity(selectedType == type ? 0 : 0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Context note

    @ViewBuilder
    private var contextNote: some View {
        switch selectedType {
        case .prayer:
            infoNote(
                icon: "lock.fill", color: .lcTeal,
                text: "Your prayer request is only seen by church staff — never public."
            )
        case .visit:
            infoNote(
                icon: "hand.wave.fill", color: .lcGold,
                text: "Let the church know when you're coming. They love welcoming new guests."
            )
        case .volunteer:
            infoNote(
                icon: "heart.fill", color: .red,
                text: "The church will follow up to connect you with their volunteer team."
            )
        default:
            EmptyView()
        }
    }

    private func infoNote(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.lcText2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(color.opacity(0.07))
        .cornerRadius(10)
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.lcTeal.opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 46))
                    .foregroundColor(.lcTeal)
            }
            VStack(spacing: 8) {
                Text("Message Sent")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.lcText)
                Text("Your \(selectedType.fullLabel.lowercased()) was sent to \(church.name). They'll be in touch.")
                    .font(.system(size: 14))
                    .foregroundColor(.lcText3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
            Spacer()
            Button("Done") { dismiss() }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.lcNavy)
                .cornerRadius(14)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.lcCream)
    }

    // MARK: - Submit logic

    private var canSubmit: Bool {
        !subject.trimmingCharacters(in: .whitespaces).isEmpty &&
        !messageBody.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submit() async {
        guard canSubmit, let userId = appState.currentUserId else { return }
        let name = appState.profile?.fullName ?? "Member"
        isSubmitting = true
        errorMessage = nil
        do {
            try await SupabaseService.shared.submitInquiry(
                memberId:   userId,
                memberName: name,
                churchSlug: church.slug,
                churchName: church.name,
                type:       selectedType.rawValue,
                subject:    subject.trimmingCharacters(in: .whitespaces),
                body:       messageBody.trimmingCharacters(in: .whitespaces)
            )
            submitted = true
        } catch {
            errorMessage = "Failed to send. Please check your connection and try again."
        }
        isSubmitting = false
    }
}
