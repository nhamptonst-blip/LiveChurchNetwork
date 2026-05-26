import SwiftUI

// Engagement controls for posts + events. Self-contained — each button
// owns its own optimistic toggle + Supabase round-trip.

// MARK: - Prayer response button

/// "I prayed for this" button for prayer-typed posts. Distinct from likes —
/// records a row in `prayer_responses` and rolls up `posts.prayer_count`.
struct PrayerResponseButton: View {
    let postId: UUID
    @Binding var prayerCount: Int
    @Binding var hasPrayed: Bool
    @EnvironmentObject var appState: AppState

    @State private var isToggling = false

    var body: some View {
        Button(action: { Task { await toggle() } }) {
            HStack(spacing: 6) {
                Text(hasPrayed ? "🙏" : "🙏")
                    .font(.system(size: 14))
                    .opacity(hasPrayed ? 1.0 : 0.55)
                Text(hasPrayed ? "I'm praying" : "I'll pray")
                    .font(.system(size: 13, weight: .semibold))
                if prayerCount > 0 {
                    Text("· \(prayerCount)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.lcText3)
                }
            }
            .foregroundColor(hasPrayed ? .lcGold : .lcText2)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(hasPrayed ? Color.lcGoldLight : Color.clear)
            )
            .overlay(
                Capsule().stroke(hasPrayed ? Color.lcGold : Color.lcBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isToggling || appState.currentUserId == nil)
    }

    private func toggle() async {
        guard let uid = appState.currentUserId else { return }
        isToggling = true
        defer { isToggling = false }
        let wasPrayed = hasPrayed
        // Optimistic update
        hasPrayed.toggle()
        prayerCount = max(0, prayerCount + (wasPrayed ? -1 : 1))
        do {
            if wasPrayed {
                try await SupabaseService.shared.unprayForPost(
                    userId: uid, postId: postId, currentCount: prayerCount + 1
                )
            } else {
                try await SupabaseService.shared.prayForPost(
                    userId: uid, postId: postId, currentCount: prayerCount - 1
                )
            }
        } catch {
            // Revert on failure
            hasPrayed = wasPrayed
            prayerCount = max(0, prayerCount + (wasPrayed ? 1 : -1))
            print("[PrayerResponseButton] toggle failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - RSVP button

/// RSVP toggle for event-typed posts and events. Records / removes a row
/// in `event_rsvps`. Caller owns the count and isAttending state.
struct RsvpButton: View {
    let eventId: UUID
    @Binding var rsvpCount: Int
    @Binding var isAttending: Bool
    @EnvironmentObject var appState: AppState

    @State private var isToggling = false

    var body: some View {
        Button(action: { Task { await toggle() } }) {
            HStack(spacing: 6) {
                Image(systemName: isAttending ? "checkmark.seal.fill" : "calendar.badge.plus")
                    .font(.system(size: 14, weight: .semibold))
                Text(isAttending ? "Going" : "RSVP")
                    .font(.system(size: 13, weight: .semibold))
                if rsvpCount > 0 {
                    Text("· \(rsvpCount)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isAttending ? .white.opacity(0.85) : .lcText3)
                }
            }
            .foregroundColor(isAttending ? .white : .lcNavy)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(isAttending ? Color.lcNavy : Color.lcNavy.opacity(0.06))
            )
            .overlay(
                Capsule().stroke(Color.lcNavy.opacity(isAttending ? 0 : 0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isToggling || appState.currentUserId == nil)
    }

    private func toggle() async {
        guard let uid = appState.currentUserId else { return }
        isToggling = true
        defer { isToggling = false }
        let wasAttending = isAttending
        isAttending.toggle()
        rsvpCount = max(0, rsvpCount + (wasAttending ? -1 : 1))
        do {
            if wasAttending {
                try await SupabaseService.shared.cancelRsvp(userId: uid, eventId: eventId)
            } else {
                try await SupabaseService.shared.rsvpToEvent(userId: uid, eventId: eventId)
            }
        } catch {
            isAttending = wasAttending
            rsvpCount = max(0, rsvpCount + (wasAttending ? 1 : -1))
            print("[RsvpButton] toggle failed: \(error.localizedDescription)")
        }
    }
}
