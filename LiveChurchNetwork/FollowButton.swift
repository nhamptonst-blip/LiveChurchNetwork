import SwiftUI

struct FollowButton: View {
    let followingId: String
    let followingType: String   // "church" | "worshipper"
    let initialIsFollowing: Bool

    @EnvironmentObject var appState: AppState
    @State private var isFollowing = false
    @State private var isToggling = false

    var body: some View {
        Group {
            if appState.currentUserId == nil {
                EmptyView()
            } else {
                Button {
                    HapticEngine.impact(.light)
                    print("[FollowButton] Clicked for \(followingType) \(followingId), isFollowing=\(isFollowing), isToggling=\(isToggling)")
                    Task { await toggleFollow() }
                } label: {
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isFollowing ? .lcNavy : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(isFollowing ? Color(red: 243/255, green: 244/255, blue: 246/255) : Color.lcNavy)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.lcNavy, lineWidth: isFollowing ? 1.5 : 0)
                        )
                }
                .disabled(isToggling)
                .contentShape(Rectangle())
            }
        }
        .onAppear {
            isFollowing = initialIsFollowing
            print("[FollowButton] Appeared with followingId=\(followingId), followingType=\(followingType), initialIsFollowing=\(initialIsFollowing)")
        }
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
