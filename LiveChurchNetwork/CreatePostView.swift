import SwiftUI
import PhotosUI
import Supabase
import Storage
                                                                                                                                                                               
struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    var onPosted: (() async -> Void)?
 
    @State private var content = ""
    @State private var videoUrl = ""
    @State private var scriptureRef = ""
    @State private var postType = "update"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isPosting = false
    @State private var errorMessage: String?

    private let postTypes = [
        ("update",       "Update",    "text.bubble"),
        ("verse",        "Verse",     "book.fill"),
        ("announcement", "Announce",  "megaphone.fill"),
        ("prayer",       "Prayer",    "hands.sparkles.fill"),
        ("event",        "Event",     "calendar"),
        ("livestream",   "Livestream", "antenna.radiowaves.left.and.right"),
    ]
                                                                                                                                                                               
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Post type selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Post Type")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.lcText2)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(postTypes, id: \.0) { type, label, icon in
                                    Button {
                                        postType = type
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: icon).font(.system(size: 11))
                                            Text(label).font(.system(size: 12, weight: .semibold))
                                        }
                                        .foregroundColor(postType == type ? .white : .lcNavy)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(postType == type ? Color.lcNavy : Color.lcNavy.opacity(0.07))
                                        .cornerRadius(20)
                                    }
                                }
                            }
                        }
                    }

                    // Type-specific form fields
                    switch postType {
                    case "verse":
                        verseFields
                    case "announcement":
                        announcementFields
                    case "prayer":
                        prayerFields
                    default:
                        defaultFields
                    }
                                                                                                                                                                               
                    if let error = errorMessage {
                        Text(error).font(.system(size: 13)).foregroundColor(.red)
                    }

                    Button {
                        Task { await post() }
                    } label: {
                        Group {
                            if isPosting {
                                ProgressView().tint(.lcText)
                            } else {
                                Text("Post")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canPost ? Color.lcGold : Color.lcBorder)
                        .foregroundColor(.lcText)
                        .cornerRadius(12)
                    }
                    .disabled(!canPost || isPosting)
                }
                .padding(20)
            }
            .background(Color.lcCream)
            .navigationTitle("New Post")
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
        }
    }
                                                                                                                                                                               
    private var canPost: Bool {
        switch postType {
        case "verse", "announcement", "prayer":
            return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImageData != nil
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
                Text("Verse Text & Reflection")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextEditor(text: $content)
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
                Text("Announcement")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextEditor(text: $content)
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

    // MARK: - Prayer fields

    private var prayerFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prayer Request")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.lcText2)
            TextEditor(text: $content)
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

    // MARK: - Default fields (update / event / livestream)

    private var defaultFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's on your heart?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextEditor(text: $content)
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Video Link (optional)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.lcText2)
                TextField("YouTube or Vimeo URL", text: $videoUrl)
                    .font(.system(size: 14))
                    .foregroundColor(.lcText)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color.lcCream)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
            }
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
                                                                                                                                                                               
        // For verse posts, scripture reference is stored in videoUrl
        let finalVideoUrl: String? = {
            if postType == "verse" {
                return scriptureRef.isEmpty ? nil : scriptureRef
            }
            return videoUrl.isEmpty ? nil : videoUrl
        }()

        do {
            try await SupabaseService.shared.createPost(
                authorId: userId,
                authorName: authorName,
                authorType: authorType,
                content: content.isEmpty ? nil : content,
                photoUrl: photoUrl,
                videoUrl: finalVideoUrl,
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
