import SwiftUI
import PhotosUI
import Supabase
import Storage
import Foundation

struct PostDetailView: View {
    let post: Post
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var isEditing = false
    @State private var editedContent = ""
    @State private var editedPhotoUrl = ""
    @State private var editedVideoUrl = ""
    @State private var isSaving = false
    @State private var authorPhotoUrl: String?
    @State private var isLoadingAuthor = true
    @State private var displayContent: String? = nil
    @State private var displayPhotoUrl: String? = nil
    @State private var checkIsOwnPost = false
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isLoadingComments = false
    @State private var isPostingComment = false
    @State private var selectedEditPhoto: PhotosPickerItem?
    @State private var editedImageData: Data?

    private var isOwnPost: Bool {
        // Use checkIsOwnPost to ensure this updates when appState changes
        _ = checkIsOwnPost
        let result = post.authorId == appState.currentUserId
        print("[PostDetailView.isOwnPost] post.authorId=\(post.authorId) vs appState.currentUserId=\(String(describing: appState.currentUserId)) => \(result)")
        return result
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isEditing {
                    editingSection
                } else {
                    viewingSection
                }
            }
            .padding(16)
        }
        .background(Color.lcCream)
        .navigationTitle(isEditing ? "Edit Post" : "Post")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            if !isEditing && isOwnPost {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit") {
                            startEditing()
                        }
                        Button("Delete", role: .destructive) {
                            // TODO: Implement delete
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.lcText3)
                    }
                }
            }
        }
        .onAppear {
            print("[PostDetailView.toolbar] isEditing=\(isEditing), isOwnPost=\(isOwnPost)")
        }
        .task {
            await loadAuthorPhoto()
            await loadComments()
            displayContent = post.content
            displayPhotoUrl = post.photoUrl
            checkIsOwnPost = true  // Trigger state update for toolbar
            // Debug: Log post and user info
            print("[PostDetailView] post.authorId=\(post.authorId), currentUserId=\(appState.currentUserId ?? UUID()), isOwnPost=\(isOwnPost)")
        }
    }

    private func loadAuthorPhoto() async {
        do {
            if let profile = try await SupabaseService.shared.getProfile(userId: post.authorId) {
                await MainActor.run {
                    self.authorPhotoUrl = profile.photoUrl
                    isLoadingAuthor = false
                }
            }
        } catch {
            print("Error loading author photo: \(error)")
            await MainActor.run { isLoadingAuthor = false }
        }
    }

    private func loadComments() async {
        await MainActor.run { isLoadingComments = true }
        do {
            let loadedComments = try await SupabaseService.shared.getComments(postId: post.id)
            await MainActor.run {
                self.comments = loadedComments
                isLoadingComments = false
            }
        } catch {
            print("Error loading comments: \(error)")
            await MainActor.run { isLoadingComments = false }
        }
    }

    private func postNewComment() async {
        guard let userId = appState.currentUserId, let profile = appState.profile else { return }
        guard !newCommentText.isEmpty else { return }

        await MainActor.run { isPostingComment = true }
        do {
            try await SupabaseService.shared.postComment(
                postId: post.id,
                userId: userId,
                authorName: profile.fullName ?? "Anonymous",
                authorPhotoUrl: profile.photoUrl,
                content: newCommentText
            )
            await MainActor.run {
                newCommentText = ""
                isPostingComment = false
            }
            // Reload comments
            await loadComments()
        } catch {
            print("Error posting comment: \(error)")
            await MainActor.run { isPostingComment = false }
        }
    }

    private var viewingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with author info
            HStack(spacing: 12) {
                if let photoUrl = authorPhotoUrl {
                    AsyncImage(url: URL(string: photoUrl)) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        } else {
                            authorInitialCircle
                        }
                    }
                } else {
                    authorInitialCircle
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(post.authorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lcText)
                    Text(formatRelativeTime(post.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)

            // Post content
            VStack(alignment: .leading, spacing: 14) {
                let displayedContent = displayContent ?? post.content
                if let content = displayedContent, !content.isEmpty {
                    Text(content)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.lcText)
                        .lineSpacing(5)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }

                let displayedPhoto = displayPhotoUrl ?? post.photoUrl
                if let photoUrl = displayedPhoto, !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                    VStack(spacing: 0) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 280)
                                    .clipped()
                                    .cornerRadius(12)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.lcBorder)
                                    .frame(height: 280)
                                    .overlay(ProgressView().tint(.lcNavy))
                            }
                        }
                    }
                }

                if let videoUrl = post.videoUrl, !videoUrl.isEmpty, let url = URL(string: videoUrl) {
                    Link(destination: url) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Watch Video")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.lcText)
                                Text(videoUrl)
                                    .font(.system(size: 11))
                                    .foregroundColor(.lcText3)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11))
                                .foregroundColor(.lcText3)
                        }
                        .padding(12)
                        .background(Color.lcCream)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.lcBorder, lineWidth: 1))
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)

            // Engagement stats
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(post.likeCount)")
                        .font(.system(size: 13))
                        .foregroundColor(.lcText2)
                }
                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)

            // Comments Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Comments")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lcText)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                if isLoadingComments {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(16)
                } else if comments.isEmpty {
                    Text("No comments yet")
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                } else {
                    VStack(spacing: 12) {
                        ForEach(comments, id: \.id) { comment in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    if let photoUrl = comment.authorPhotoUrl, let url = URL(string: photoUrl) {
                                        AsyncImage(url: url) { phase in
                                            if case .success(let img) = phase {
                                                img.resizable().scaledToFill()
                                                    .frame(width: 32, height: 32)
                                                    .clipShape(Circle())
                                            } else {
                                                avatarPlaceholder(comment.authorName)
                                            }
                                        }
                                    } else {
                                        avatarPlaceholder(comment.authorName)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(comment.authorName)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.lcText)
                                        Text(formatRelativeTime(comment.createdAt))
                                            .font(.system(size: 10))
                                            .foregroundColor(.lcText3)
                                    }
                                    Spacer()
                                }

                                Text(comment.content)
                                    .font(.system(size: 12))
                                    .foregroundColor(.lcText2)
                                    .lineLimit(nil)
                            }
                            .padding(12)
                            .background(Color.lcCream)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Add comment input
                if appState.currentUserId != nil {
                    VStack(spacing: 8) {
                        TextEditor(text: $newCommentText)
                            .frame(minHeight: 60)
                            .font(.system(size: 12))
                            .foregroundColor(.lcText)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.lcBorder, lineWidth: 1))

                        Button(action: { Task { await postNewComment() } }) {
                            if isPostingComment {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Post Comment")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.lcNavy)
                        .cornerRadius(8)
                        .disabled(newCommentText.isEmpty || isPostingComment)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                } else {
                    Text("Sign in to comment")
                        .font(.system(size: 12))
                        .foregroundColor(.lcText3)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                }
            }
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    private var editingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Content")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.lcText3)

                TextEditor(text: $editedContent)
                    .frame(minHeight: 120)
                    .font(.system(size: 15))
                    .foregroundColor(.lcText)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.lcBorder, lineWidth: 1))

                Divider()
                    .padding(.vertical, 4)

                // Photo section
                Text("Photo")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.lcText3)

                // Simplified photo section for debugging
                VStack(spacing: 12) {
                    if let imageData = editedImageData, let uiImage = UIImage(data: imageData) {
                        // Branch 1: New photo selected
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(8)

                        HStack(spacing: 8) {
                            PhotosPicker(selection: $selectedEditPhoto, matching: .images) {
                                Text("Change Photo")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.lcNavy)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(Color.white)
                                    .cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.lcNavy, lineWidth: 1))
                            }

                            Button(action: { editedImageData = nil; selectedEditPhoto = nil; editedPhotoUrl = "" }) {
                                Text("Remove")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(Color.white)
                                    .cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red, lineWidth: 1))
                            }
                        }
                    } else if !editedPhotoUrl.isEmpty {
                        // Branch 2: Existing photo
                        AsyncImage(url: URL(string: editedPhotoUrl)) { phase in
                            if case .success(let img) = phase {
                                img.resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(8)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.lcBorder)
                                    .frame(height: 200)
                            }
                        }

                        HStack(spacing: 8) {
                            PhotosPicker(selection: $selectedEditPhoto, matching: .images) {
                                Text("Replace Photo")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.lcNavy)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(Color.white)
                                    .cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.lcNavy, lineWidth: 1))
                            }

                            Button(action: { editedPhotoUrl = "" }) {
                                Text("Remove")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(Color.white)
                                    .cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red, lineWidth: 1))
                            }
                        }
                    } else {
                        // Branch 3: No photo - show picker
                        PhotosPicker(selection: $selectedEditPhoto, matching: .images) {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundColor(.lcNavy)
                                Text("Add Photo")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.lcNavy)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(Color.lcCream)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.lcBorder, style: StrokeStyle(lineWidth: 1.5, dash: [5])))
                        }
                    }
                }
            }
            .onChange(of: selectedEditPhoto) { newPhoto in
                print("[PostDetailView] Photo selected: \(newPhoto != nil)")
                Task {
                    if let data = try await newPhoto?.loadTransferable(type: Data.self) {
                        print("[PostDetailView] Photo data loaded: \(data.count) bytes")
                        await MainActor.run {
                            self.editedImageData = data
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Button(action: {
                    isEditing = false
                    editedImageData = nil
                    selectedEditPhoto = nil
                }) {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.lcNavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.lcNavy, lineWidth: 1.5))
                }

                Button(action: { Task { await saveChanges() } }) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Save")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.lcNavy)
                .cornerRadius(8)
                .disabled(isSaving)
            }
        }
    }

    private var authorInitialCircle: some View {
        ZStack {
            Circle()
                .fill(Color.lcNavy.opacity(0.1))
            Text(post.authorName.prefix(1).uppercased())
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lcNavy)
        }
        .frame(width: 44, height: 44)
    }

    private func avatarPlaceholder(_ name: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.lcNavy.opacity(0.1))
            Text(name.prefix(1).uppercased())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.lcNavy)
        }
        .frame(width: 32, height: 32)
    }

    private func startEditing() {
        editedContent = displayContent ?? post.content ?? ""
        editedPhotoUrl = displayPhotoUrl ?? post.photoUrl ?? ""
        editedVideoUrl = post.videoUrl ?? ""
        isEditing = true
        print("[PostDetailView.startEditing] isEditing=true, editedPhotoUrl='\(editedPhotoUrl)', hasContent=\(!editedContent.isEmpty)")
    }

    private func saveChanges() async {
        isSaving = true
        var finalPhotoUrl = editedPhotoUrl

        // Upload new photo if selected
        if let imageData = editedImageData {
            let path = "posts/\(UUID().uuidString).jpg"
            do {
                try await SupabaseService.shared.client.storage
                    .from("posts")
                    .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))
                let url = try SupabaseService.shared.client.storage
                    .from("posts")
                    .getPublicURL(path: path)
                finalPhotoUrl = url.absoluteString
            } catch {
                print("Photo upload error: \(error)")
                await MainActor.run { isSaving = false }
                return
            }
        }

        do {
            try await SupabaseService.shared.updatePost(
                postId: post.id,
                content: editedContent,
                photoUrl: finalPhotoUrl.isEmpty ? nil : finalPhotoUrl
            )
            await MainActor.run {
                displayContent = editedContent
                displayPhotoUrl = finalPhotoUrl.isEmpty ? nil : finalPhotoUrl
                editedImageData = nil
                selectedEditPhoto = nil
                isEditing = false
                isSaving = false
                HapticEngine.impact(.light)
            }
        } catch {
            print("Error saving post: \(error)")
            await MainActor.run { isSaving = false }
        }
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        switch diff {
        case ..<60:       return "just now"
        case ..<3600:     return "\(Int(diff/60))m ago"
        case ..<86400:    return "\(Int(diff/3600))h ago"
        default:          return "\(Int(diff/86400))d ago"
        }
    }
}
