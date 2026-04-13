import SwiftUI

struct FollowButton: View {
    let followingId: String
    let followingType: String   // "church" | "worshipper"

    @EnvironmentObject var appState: AppState
    @State private var isFollowing = false
    @State private var isLoading = true
    @State private var isToggling = false

    var body: some View {
        Group {
            if appState.isGuest || appState.currentUserId == nil {
                EmptyView()
            } else if isLoading {
                ProgressView().tint(.lcNavy).scaleEffect(0.7)
                    .frame(width: 72, height: 28)
            } else {
                Button {
                    Task { await toggleFollow() }
                } label: {
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isFollowing ? .lcNavy : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(isFollowing ? Color.clear : Color.lcNavy)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.lcNavy, lineWidth: isFollowing ? 1.5 : 0)
                        )
                }
                .disabled(isToggling)
            }
        }
        .task { await checkFollowing() }
    }

    private func checkFollowing() async {
        guard let userId = appState.currentUserId else { isLoading = false; return }
        do {
            let follows = try await SupabaseService.shared.getFollowing(followerId: userId)
            isFollowing = follows.contains { $0.followingId == followingId }
        } catch {
            print("Check follow error: \(error)")
        }
        isLoading = false
    }

    private func toggleFollow() async {
        guard let userId = appState.currentUserId else { return }
        isToggling = true
        do {
            if isFollowing {
                try await SupabaseService.shared.unfollow(followerId: userId, followingId: followingId)
                isFollowing = false
            } else {
                try await SupabaseService.shared.follow(followerId: userId, followingId: followingId, followingType: followingType)
                isFollowing = true
            }
        } catch {
            print("Toggle follow error: \(error)")
        }
        isToggling = false
    }
}
