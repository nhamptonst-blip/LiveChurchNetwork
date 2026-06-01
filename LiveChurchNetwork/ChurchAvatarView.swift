import SwiftUI

// MARK: - Church Avatar View
//
// Single source-of-truth avatar for any `Church`. Mirrors `UserAvatarView`
// but for churches: loads `church.image` via AsyncImage and falls back to
// a denomination-hashed gradient with the church's first initial.
//
// Use this everywhere a church logo/profile picture is rendered. The
// goal is visual consistency across the directory, search results, post
// cards, story rings, and the church detail header so a church without
// an uploaded logo always looks the same to the user.
//
// Shape:
//   - `cornerRadius == nil` → circle (default — most card surfaces).
//   - `cornerRadius == N`   → rounded square with corner radius `N`
//                             (used by tile-style cards like
//                             NearbyChurchCard and SearchResultsCard).
//
// Example:
//   ChurchAvatarView(church: church, size: 84, cornerRadius: 18)
//   ChurchAvatarView(church: church, size: 50)   // circle

struct ChurchAvatarView: View {
    let imageURL: String
    let name: String
    let denomination: String
    let size: CGFloat
    var cornerRadius: CGFloat? = nil

    /// Render directly for a `Church`. The most common caller.
    init(church: Church, size: CGFloat, cornerRadius: CGFloat? = nil) {
        self.imageURL = church.image
        self.name = church.name
        self.denomination = church.denomination
        self.size = size
        self.cornerRadius = cornerRadius
    }

    /// Render for a `ChurchSubmission` (camel-cased + optional fields).
    /// Used by feed/suggestion surfaces that work with raw submission rows.
    init(submission: ChurchSubmission, size: CGFloat, cornerRadius: CGFloat? = nil) {
        self.imageURL = submission.avatarUrl ?? ""
        self.name = submission.churchName ?? ""
        self.denomination = submission.denomination ?? ""
        self.size = size
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Group {
            if !imageURL.isEmpty, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .clipShape(clipShape)
    }

    // MARK: - Fallback

    private var fallback: some View {
        ZStack {
            ChurchAvatarView.denominationGradient(for: denomination)
            Text(initial)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(1)).uppercased()
    }

    // MARK: - Shape

    private var clipShape: AnyShape {
        if let r = cornerRadius {
            return AnyShape(RoundedRectangle(cornerRadius: r))
        }
        return AnyShape(Circle())
    }

    // MARK: - Gradient palette
    //
    // Same 5-colour palette previously copy-pasted into NearbyChurchCard,
    // FeaturedChurchCard, DirectoryChurchCard, etc. Exposed `static` so any
    // future component that wants the same colour for a given denomination
    // (e.g. a cover banner) can reuse it without duplicating the hash.

    static func denominationGradient(for denomination: String) -> LinearGradient {
        let hash = denomination.hashValue % 5
        let colors: (top: Color, bottom: Color) = {
            switch hash {
            case 0:  return (Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.1, green: 0.3, blue: 0.7))
            case 1:  return (Color(red: 0.8, green: 0.3, blue: 0.3), Color(red: 0.7, green: 0.2, blue: 0.2))
            case 2:  return (Color(red: 0.3, green: 0.6, blue: 0.4), Color(red: 0.2, green: 0.5, blue: 0.3))
            case 3:  return (Color(red: 0.8, green: 0.5, blue: 0.2), Color(red: 0.7, green: 0.4, blue: 0.1))
            default: return (Color(red: 0.6, green: 0.3, blue: 0.7), Color(red: 0.5, green: 0.2, blue: 0.6))
            }
        }()
        return LinearGradient(
            gradient: Gradient(colors: [colors.top, colors.bottom]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            ChurchAvatarView(
                church: Church(
                    name: "Grace Cathedral", slug: "g", image: "",
                    denomination: "Episcopal", permalink: "", phone: "",
                    website: "", serviceTimes: "", about: "", isLive: false
                ),
                size: 84, cornerRadius: 18
            )
            ChurchAvatarView(
                church: Church(
                    name: "Bethel Live", slug: "b", image: "",
                    denomination: "Pentecostal", permalink: "", phone: "",
                    website: "", serviceTimes: "", about: "", isLive: true
                ),
                size: 50
            )
            ChurchAvatarView(
                church: Church(
                    name: "Faith Center", slug: "f", image: "",
                    denomination: "Baptist", permalink: "", phone: "",
                    website: "", serviceTimes: "", about: "", isLive: false
                ),
                size: 42, cornerRadius: 10
            )
        }
    }
    .padding()
}
