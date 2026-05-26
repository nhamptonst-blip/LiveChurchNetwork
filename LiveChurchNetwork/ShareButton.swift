import SwiftUI

/// Native iOS share sheet trigger with a polished, brand-consistent label.
/// Wraps SwiftUI's built-in `ShareLink` so call sites stay one-liners.
///
/// Usage:
///   ChurchShareLink(slug: "mjd-church", churchName: "MJD Church")
///
/// Renders an `↗ Share` capsule. Tapping it shows the system share sheet
/// with a deep-link to the public profile + a friendly title.
struct ChurchShareLink: View {
    let slug: String
    let churchName: String
    var compact: Bool = false

    private var shareURL: URL {
        URL(string: "https://livechurchnetwork.com/church/\(slug)")
            ?? URL(string: "https://livechurchnetwork.com")!
    }

    var body: some View {
        ShareLink(
            item: shareURL,
            subject: Text("Check out \(churchName) on Live Church Network"),
            message: Text("\(churchName) — service times, livestream, and community on Live Church Network.")
        ) {
            label
        }
    }

    @ViewBuilder
    private var label: some View {
        if compact {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.lcText2)
                .padding(8)
                .background(Circle().fill(Color.white))
                .overlay(Circle().stroke(Color.lcBorder, lineWidth: 1))
        } else {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.up")
                Text("Share")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.lcText2)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white)
            .overlay(Capsule().stroke(Color.lcBorder, lineWidth: 1))
            .clipShape(Capsule())
        }
    }
}

/// Generic share-link wrapper for any URL — used by feed posts, events, and
/// worshipper profiles where the destination isn't a church slug.
struct AppShareLink: View {
    let url: URL
    let title: String
    let message: String?
    var compact: Bool = false

    var body: some View {
        if let msg = message {
            ShareLink(item: url, subject: Text(title), message: Text(msg)) { label }
        } else {
            ShareLink(item: url, subject: Text(title)) { label }
        }
    }

    @ViewBuilder
    private var label: some View {
        if compact {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.lcText2)
        } else {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.up")
                Text("Share")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.lcText2)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white)
            .overlay(Capsule().stroke(Color.lcBorder, lineWidth: 1))
            .clipShape(Capsule())
        }
    }
}
