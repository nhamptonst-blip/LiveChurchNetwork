import SwiftUI

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

    private var isOwnPost: Bool {
        post.authorId == appState.currentUserId
    }

    var body: some View {
        NavigationStack {
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
            .task {
                await loadAuthorPhoto()
            }
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

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.lcText)
                    Text(formatRelativeTime(post.createdAt))
                        .font(.system(size: 11))
                        .foregroundColor(.lcText3)
                }

                Spacer()

                if isOwnPost {
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
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)

            // Post content
            VStack(alignment: .leading, spacing: 12) {
                if let content = post.content, !content.isEmpty {
                    Text(content)
                        .font(.system(size: 15))
                        .foregroundColor(.lcText)
                        .lineSpacing(4)
                }

                if let photoUrl = post.photoUrl, !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 240)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.lcBorder)
                                .frame(height: 240)
                                .overlay(ProgressView().tint(.lcNavy))
                        }
                    }
                }

                if let videoUrl = post.videoUrl, !videoUrl.isEmpty {
                    Link(destination: URL(string: videoUrl) ?? URL(string: "https://youtube.com")!) {
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
            .padding(14)
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
            .padding(14)
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

                if let photoUrl = post.photoUrl, !photoUrl.isEmpty {
                    VStack(alignment: .trailing) {
                        AsyncImage(url: URL(string: photoUrl)) { phase in
                            if case .success(let img) = phase {
                                img.resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                        }
                        Button(action: { editedPhotoUrl = "" }) {
                            Text("Remove Photo")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Button(action: { isEditing = false }) {
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

    private func startEditing() {
        editedContent = post.content ?? ""
        editedPhotoUrl = post.photoUrl ?? ""
        editedVideoUrl = post.videoUrl ?? ""
        isEditing = true
    }

    private func saveChanges() async {
        isSaving = true
        do {
            try await SupabaseService.shared.updatePost(
                postId: post.id,
                content: editedContent,
                photoUrl: editedPhotoUrl.isEmpty ? nil : editedPhotoUrl
            )
            await MainActor.run {
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
