import SwiftUI

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    var onCreated: (() async -> Void)?

    @State private var title       = ""
    @State private var eventDate   = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var location    = ""
    @State private var description = ""
    @State private var isCreating  = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    fieldGroup("EVENT NAME") {
                        TextField("e.g. Sunday Morning Worship", text: $title)
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
                        TextField("e.g. Main Sanctuary or Online", text: $location)
                            .styledField()
                    }

                    fieldGroup("DESCRIPTION (OPTIONAL)") {
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("A brief description of the event…")
                                    .font(.system(size: 14))
                                    .foregroundColor(.lcText3)
                                    .padding(.horizontal, 14).padding(.top, 13)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $description)
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

                    if let error = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red)
                            Text(error).font(.system(size: 13)).foregroundColor(.red)
                        }
                    }

                    Button {
                        Task { await createEvent() }
                    } label: {
                        Group {
                            if isCreating {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Event")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(isValid ? Color.lcNavy : Color.lcNavy.opacity(0.35))
                        .cornerRadius(14)
                    }
                    .disabled(!isValid || isCreating)
                }
                .padding(24)
                .padding(.bottom, 32)
            }
            .background(Color.lcCream)
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
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

    private func createEvent() async {
        guard let userId = appState.currentUserId,
              let profile = appState.profile else { return }
        isCreating = true
        errorMessage = nil
        do {
            try await SupabaseService.shared.createEvent(
                authorId:    userId,
                authorName:  profile.fullName ?? "Church",
                title:       title.trimmingCharacters(in: .whitespaces),
                description: description.isEmpty ? nil : description,
                eventDate:   eventDate,
                location:    location.isEmpty ? nil : location
            )
            if let callback = onCreated {
                await callback()
            }
            dismiss()
        } catch {
            errorMessage = "Could not create event. Please try again."
        }
        isCreating = false
    }
}
