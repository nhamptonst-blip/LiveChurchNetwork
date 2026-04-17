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
            if appState.currentUserId == nil {
                EmptyView()
            } else if isLoading {
                ProgressView().tint(.lcNavy).scaleEffect(0.7)
                    .frame(width: 72, height: 28)
            } else {
                Button {
                    print("[FollowButton] Clicked for \(followingType) \(followingId), isFollowing=\(isFollowing), isToggling=\(isToggling)")
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
        .onAppear { print("[FollowButton] Appeared with followingId=\(followingId), followingType=\(followingType)") }
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
        print("[FollowButton.toggleFollow] Starting for \(followingType) \(followingId), currently following: \(isFollowing)")
        guard let userId = appState.currentUserId else {
            print("[FollowButton.toggleFollow] No user ID")
            return
        }
        isToggling = true
        do {
            if isFollowing {
                print("[FollowButton.toggleFollow] Unfollowing...")
                try await SupabaseService.shared.unfollow(followerId: userId, followingId: followingId)
                isFollowing = false
                print("[FollowButton.toggleFollow] Unfollow successful")
            } else {
                print("[FollowButton.toggleFollow] Following...")
                try await SupabaseService.shared.follow(followerId: userId, followingId: followingId, followingType: followingType)
                isFollowing = true
                print("[FollowButton.toggleFollow] Follow successful")
            }
        } catch {
            print("[FollowButton.toggleFollow] Error: \(error)")
        }
        isToggling = false
    }
}
