import SwiftUI

struct FollowButton: View {
    let followingId: String
    let followingType: String   // "church" | "worshipper"
    let initialIsFollowing: Bool

    @EnvironmentObject var appState: AppState
    @State private var isFollowing = false
    @State private var isToggling = false
    @State private var isPressed = false

    var body: some View {
        Group {
            if appState.currentUserId == nil {
                EmptyView()
            } else {
                Button {
                    HapticEngine.impact(.light)
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
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .opacity(isPressed ? 0.8 : 1.0)
                .animation(.easeOut(duration: 0.1), value: isPressed)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
            }
        }
        .onAppear {
            isFollowing = initialIsFollowing
        }
    }

    private func toggleFollow() async {
        guard let userId = appState.currentUserId else {
            return
        }
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
            // Silent fail with state rollback
        }
        isToggling = false
    }
}
