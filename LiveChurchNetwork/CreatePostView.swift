import SwiftUI
import PhotosUI
import Supabase
import Storage
                                                                                                                                                                               
struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    var onPosted: (() async -> Void)?

    // Shared fields
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isPosting = false
    @State private var errorMessage: String?
    @State private var postType = "update"

    // Update fields
    @State private var updateContent = ""

    // Verse fields
    @State private var scriptureRef = ""
    @State private var verseText = ""
    @State private var reflection = ""

    // Event fields
    @State private var eventTitle = ""
    @State private var eventDate = Date()
    @State private var eventTime = Date()
    @State private var eventLocation = ""
    @State private var eventDescription = ""

    // Livestream fields
    @State private var streamTitle = ""
    @State private var streamUrl = ""
    @State private var streamTime = Date()
    @State private var streamDescription = ""

    // Prayer fields
    @State private var prayerTitle = ""
    @State private var prayerMessage = ""

    // Announcement fields
    @State private var announcementTitle = ""
    @State private var announcementBody = ""

    private let postTypeConfigs: [(value: String, label: String, description: String, icon: String)] = [
        ("update", "Update", "Share news", "text.bubble"),
        ("verse", "Verse", "Share scripture", "book.fill"),
        ("event", "Event", "Announce event", "calendar"),
        ("livestream", "Stream", "Go live", "antenna.radiowaves.left.and.right"),
        ("prayer", "Prayer", "Request prayer", "hands.sparkles.fill"),
        ("announcement", "Announce", "Important notice", "megaphone.fill"),
    ]
                                                                                                                                                                               
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Post type selector grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("POST TYPE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.lcText2)
                            .tracking(0.5)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(postTypeConfigs, id: \.value) { config in
                                Button {
                                    postType = config.value
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: config.icon)
                                            .font(.system(size: 18))
                                        Text(config.label)
                                            .font(.system(size: 12, weight: .bold))
                                        Text(config.description)
                                            .font(.system(size: 10))
                                            .foregroundColor(.lcText3)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(postType == config.value ? Color.lcNavy.opacity(0.1) : Color.white)
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(postType == config.value ? Color.lcNavy : Color.lcBorder, lineWidth: 1.5))
                                    .cornerRadius(10)
                                    .foregroundColor(postType == config.value ? .lcNavy : .lcText2)
                                }
                            }
                        }
                    }

                    // Type-specific form sections
                    formFields

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }

                    Button {
                        Task { await post() }
                    } label: {
                        Group {
                            if isPosting {
                                ProgressView().tint(.lcText)
                            } else {
                                Text("Publish Post")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canPost && !isPosting ? Color.lcNavy : Color.lcBorder)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canPost || isPosting)
                }
                .padding(20)
            }
            .background(Color.lcCream)
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.lcNavy)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var formFields: some View {
        switch postType {
        case "update":
            updateFields
        case "verse":
            verseFields
        case "event":
            eventFields
        case "livestream":
            livestreamFields
        case "prayer":
            prayerFields
        case "announcement":
            announcementFields
        default:
            updateFields
        }
    }
                                                                                                                                                                               
    private var canPost: Bool {
        switch postType {
        case "update":
            return !updateContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImageData != nil
        case "verse":
            return !scriptureRef.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !verseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case "event":
            return !eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !eventLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case "livestream":
            return !streamTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   isValidUrl(streamUrl) &&
                   !streamUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case "prayer":
            return !prayerTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !prayerMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case "announcement":
            return !announcementTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !announcementBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return false
        }
    }

    private func isValidUrl(_ url: String) -> Bool {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        guard let url = URL(string: trimmed) else { return false }
        return url.scheme != nil && (url.host != nil || url.path.count > 1)
    }

    // MARK: - Update fields

    private var updateFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextEditor(text: $updateContent)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(10)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
            photoPicker
        }
    }

    // MARK: - Verse fields

    private var verseFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Scripture Reference")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextField("e.g. John 3:16", text: $scriptureRef)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .padding(12)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Verse Text")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextEditor(text: $verseText)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(10)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Reflection (Optional)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextEditor(text: $reflection)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
            photoPicker
        }
    }

    // MARK: - Event fields

    private var eventFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Event Title")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextField("What's happening?", text: $eventTitle)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .padding(12)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Date")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                DatePicker("", selection: $eventDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .foregroundColor(.lcText)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Time")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                DatePicker("", selection: $eventTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .foregroundColor(.lcText)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextField("Where will this take place?", text: $eventLocation)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .padding(12)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextEditor(text: $eventDescription)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(10)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
            photoPicker
        }
    }

    // MARK: - Livestream fields

    private var livestreamFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Stream Title")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextField("What are you streaming?", text: $streamTitle)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .padding(12)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Livestream URL")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextField("https://youtube.com/... or https://twitch.tv/...", text: $streamUrl)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
                if !streamUrl.isEmpty && !isValidUrl(streamUrl) {
                    Text("Please enter a valid URL")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Start Time")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                DatePicker("", selection: $streamTime, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .foregroundColor(.lcText)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextEditor(text: $streamDescription)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
        }
    }

    // MARK: - Prayer fields

    private var prayerFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Prayer Title")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextField("What do you need prayer for?", text: $prayerTitle)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .padding(12)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Prayer Request")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextEditor(text: $prayerMessage)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(10)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
        }
    }

    // MARK: - Announcement fields

    private var announcementFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Announcement Title")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextField("What do you want to announce?", text: $announcementTitle)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .padding(12)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Announcement Body")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextEditor(text: $announcementBody)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(10)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
            photoPicker
        }
    }

    // MARK: - Shared photo picker

    private var photoPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photo (optional)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.lcText2)
            if let imageData = selectedImageData,
               let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFill()
                        .frame(height: 180).clipped().cornerRadius(10)
                    Button {
                        selectedImageData = nil
                        selectedPhoto = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 22))
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
            } else {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: "photo").foregroundColor(.lcNavy)
                        Text("Choose Photo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcNavy)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.lcNavy.opacity(0.06))
                    .cornerRadius(10)
                }
                .onChange(of: selectedPhoto) { item in
                    Task {
                        selectedImageData = try? await item?.loadTransferable(type: Data.self)
                    }
                }
            }
        }
    }

    private func post() async {
        guard let userId = appState.currentUserId,
              let profile = appState.profile else { return }
        isPosting = true
        errorMessage = nil

        var photoUrl: String? = nil
        if let imageData = selectedImageData {
            let path = "posts/\(UUID().uuidString).jpg"
            do {
                try await SupabaseService.shared.client.storage
                    .from("posts")
                    .upload(path, data: imageData,
                            options: FileOptions(contentType: "image/jpeg"))
                let url = try SupabaseService.shared.client.storage
                    .from("posts")
                    .getPublicURL(path: path)
                photoUrl = url.absoluteString
            } catch {
                print("Photo upload error: \(error)")
            }
        }

        let authorType = (profile.role == "church_admin") ? "church" : "worshipper"
        let authorName = profile.fullName ?? "Anonymous"

        // Build content based on post type
        var postContent = ""
        var videoUrlForPost: String? = nil

        switch postType {
        case "update":
            postContent = updateContent

        case "verse":
            postContent = "\(scriptureRef)\n\n\(verseText)"
            if !reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                postContent += "\n\n\(reflection)"
            }

        case "event":
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let dateStr = dateFormatter.string(from: eventDate)
            let timeStr = timeFormatter.string(from: eventTime)
            postContent = "\(eventTitle)\n\nDate: \(dateStr)\nTime: \(timeStr)\nLocation: \(eventLocation)\n\n\(eventDescription)"

        case "livestream":
            postContent = streamDescription.isEmpty ? streamTitle : streamDescription
            videoUrlForPost = streamUrl

        case "prayer":
            postContent = "\(prayerTitle)\n\n\(prayerMessage)"

        case "announcement":
            postContent = "\(announcementTitle)\n\n\(announcementBody)"

        default:
            postContent = updateContent
        }

        do {
            try await SupabaseService.shared.createPost(
                authorId: userId,
                authorName: authorName,
                authorType: authorType,
                content: postContent.isEmpty ? nil : postContent,
                photoUrl: photoUrl,
                videoUrl: videoUrlForPost,
                postType: postType
            )
            await onPosted?()
            dismiss()
        } catch {
            errorMessage = "Could not post. Please try again."
        }
        isPosting = false
    }
}
