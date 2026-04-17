import SwiftUI

// MARK: - Avatar Size

enum AvatarSize {
    case small    // 36 pt — activity lists, compact rows
    case feed     // 42 pt — feed post headers
    case medium   // 52 pt — discovery cards, follower lists
    case large    // 82 pt — profile page hero

    var diameter: CGFloat {
        switch self {
        case .small:  return 36
        case .feed:   return 42
        case .medium: return 52
        case .large:  return 82
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small:  return 13
        case .feed:   return 16
        case .medium: return 17
        case .large:  return 26
        }
    }
}

// MARK: - User Avatar View
//
// Single source-of-truth avatar for any DiscoverableUser.
// Loads user.photoUrl via AsyncImage; falls back to a teal initials circle.
// Sizing is driven by AvatarSize — use the same size token everywhere
// so the same user always looks identical across the app.
//
// Profile page usage (white border ring):
//   ZStack {
//       Circle().fill(.white).frame(width: 88, height: 88).shadow(...)
//       UserAvatarView(user: user, size: .large)
//       Circle().stroke(.white, lineWidth: 3).frame(width: 88, height: 88)
//   }

struct UserAvatarView: View {
    let user: DiscoverableUser
    let size: AvatarSize

    private var initials: String {
        let parts = user.name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(user.name.prefix(2)).uppercased()
    }

    var body: some View {
        Group {
            if let urlStr = user.photoUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                            .transition(.opacity.animation(.appFadeIn))
                    default:
                        fallbackCircle
                    }
                }
            } else {
                fallbackCircle
            }
        }
        .frame(width: size.diameter, height: size.diameter)
        .clipShape(Circle())
    }

    private var fallbackCircle: some View {
        ZStack {
            Circle().fill(Color.lcTeal)
            Text(initials)
                .font(.system(size: size.fontSize, weight: .black))
                .foregroundColor(.white)
        }
    }
}
