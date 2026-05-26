import SwiftUI

/// Primary creation hub for the church admin dashboard.
/// Large prompt + 6 icon-forward tiles in a responsive 3×2 grid. Tapping any
/// tile launches CreatePostView (or CreateEventView) pre-selected to that
/// post type.
///
/// 1:1 visual port of web's <ChurchQuickComposer/>.
struct QuickComposer: View {
    let churchAvatarUrl: String?
    let churchName: String
    /// Called when the worshipper picks a post-type tile.
    /// Receives the post-type slug ("announcement", "verse", "prayer",
    /// "update" — used for sermon — or "livestream"). The hosting view
    /// translates that into a sheet presentation of CreatePostView.
    let onSelectPostType: (String) -> Void
    /// Called when the user taps the Event tile — events have a separate
    /// composer (CreateEventView) so the hosting view manages that flow.
    let onSelectEvent: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            promptRow
            tileGrid
        }
        .padding(20)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Prompt row

    private var promptRow: some View {
        HStack(spacing: 14) {
            avatar
            Button(action: { onSelectPostType("update") }) {
                HStack {
                    Text("What's happening at \(churchName)?")
                        .font(.system(size: 16))
                        .foregroundColor(.lcText3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Color.lcCream.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.lcBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let url = churchAvatarUrl, !url.isEmpty, let parsed = URL(string: url) {
            AsyncImage(url: parsed) { phase in
                if let img = phase.image {
                    img.resizable().scaledToFill()
                } else {
                    avatarFallback
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.lcBorder, lineWidth: 1))
        } else {
            avatarFallback
        }
    }

    private var avatarFallback: some View {
        Circle()
            .fill(Color.lcNavy)
            .frame(width: 48, height: 48)
            .overlay(
                Text(String((churchName.first ?? "C")).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    // MARK: - Tile grid

    private struct TileSpec: Identifiable {
        let id: String
        let label: String
        let description: String
        let icon: String
        let accent: LinearGradient
        let foreground: Color
        let action: () -> Void
    }

    private var tiles: [TileSpec] {
        [
            TileSpec(
                id: "announcement",
                label: "Announcement",
                description: "Share church news",
                icon: "📣",
                accent: gradient(.lcNavy.opacity(0.15), .lcNavy.opacity(0.05)),
                foreground: .lcNavy,
                action: { onSelectPostType("announcement") }
            ),
            TileSpec(
                id: "scripture",
                label: "Scripture",
                description: "Verse + reflection",
                icon: "📖",
                accent: gradient(.lcGold.opacity(0.25), .lcGoldLight.opacity(0.4)),
                foreground: .lcGold,
                action: { onSelectPostType("verse") }
            ),
            TileSpec(
                id: "prayer",
                label: "Prayer",
                description: "Request prayer",
                icon: "🙏",
                accent: gradient(Color.purple.opacity(0.18), Color.purple.opacity(0.08)),
                foreground: .purple,
                action: { onSelectPostType("prayer") }
            ),
            TileSpec(
                id: "event",
                label: "Event",
                description: "Create gathering",
                icon: "📅",
                accent: gradient(.lcTeal.opacity(0.20), .lcTeal.opacity(0.05)),
                foreground: .lcTeal,
                action: { onSelectEvent() }
            ),
            TileSpec(
                id: "sermon",
                label: "Sermon",
                description: "Upload a message",
                icon: "🎤",
                accent: gradient(Color.orange.opacity(0.18), Color.orange.opacity(0.08)),
                foreground: .orange,
                action: { onSelectPostType("update") }
            ),
            TileSpec(
                id: "livestream",
                label: "Livestream",
                description: "Schedule a stream",
                icon: "📡",
                accent: gradient(Color.red.opacity(0.18), Color.red.opacity(0.08)),
                foreground: .red,
                action: { onSelectPostType("livestream") }
            ),
        ]
    }

    private var tileGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12),
                       GridItem(.flexible(), spacing: 12),
                       GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(tiles) { tile in
                Button(action: tile.action) {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(tile.accent)
                                .frame(width: 48, height: 48)
                            Text(tile.icon).font(.system(size: 24))
                        }
                        Text(tile.label)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.lcText)
                            .lineLimit(1)
                        Text(tile.description)
                            .font(.system(size: 11))
                            .foregroundColor(.lcText3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 8)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.lcBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(QuickComposerTileStyle())
            }
        }
    }

    private func gradient(_ a: Color, _ b: Color) -> LinearGradient {
        LinearGradient(colors: [a, b], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct QuickComposerTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
