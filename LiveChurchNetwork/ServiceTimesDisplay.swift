import SwiftUI

/// Premium structured display for the public church profile. Each row reads
/// as: Day (label) · Time (prominent) · Service type (sub) · Attendance badge.
/// Collapses to `initialRowLimit` rows by default with a "See full schedule"
/// toggle so the card stays scannable when a church has many services.
///
/// 1:1 visual port of the web app's <ServiceTimesDisplay/> component.
struct ServiceTimesDisplay: View {
    let services: [ServiceTime]
    var initialRowLimit: Int = 2

    @State private var expanded = false

    var body: some View {
        guard !services.isEmpty else {
            return AnyView(EmptyView())
        }

        let now = Date()
        let live = ScheduleHelpers.findLiveService(services, now: now)
        let groups = ScheduleHelpers.groupByDay(services)
        let allRows: [ServiceTime] = groups.flatMap { $0.entries }
        let visibleRows = expanded ? allRows : Array(allRows.prefix(initialRowLimit))
        let hidden = allRows.count - visibleRows.count

        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 8) {
                    Text("📅")
                    Text("Service Times")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.lcText)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

                // Rows
                ForEach(Array(visibleRows.enumerated()), id: \.element.id) { idx, s in
                    let isLive = live?.id == s.id
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.day.label.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(.lcText3)

                            Text(ScheduleHelpers.formatTimeRange(s.startTime, s.endTime))
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(.lcText)

                            Text(s.serviceType)
                                .font(.system(size: 12))
                                .foregroundColor(.lcText2)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            attendanceBadge(livestream: s.livestream)
                            if isLive {
                                liveNowPill
                            }
                            if !s.language.isEmpty && s.language != "English" {
                                Text(s.language)
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.lcTeal.opacity(0.10))
                                    .foregroundColor(.lcTeal)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(isLive ? Color.red.opacity(0.04) : Color.clear)

                    if idx < visibleRows.count - 1 {
                        Divider().background(Color.lcBorder.opacity(0.6))
                    }
                }

                if hidden > 0 {
                    Divider().background(Color.lcBorder)
                    Button(action: { withAnimation(.easeInOut(duration: 0.18)) { expanded = true } }) {
                        HStack(spacing: 6) {
                            Text("SEE FULL SCHEDULE")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.lcNavy)
                            Text("(+\(hidden) more service\(hidden == 1 ? "" : "s"))")
                                .font(.system(size: 12))
                                .foregroundColor(.lcText3)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.lcBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        )
    }

    @ViewBuilder
    private func attendanceBadge(livestream: Bool) -> some View {
        let label = livestream ? "IN PERSON + ONLINE" : "IN PERSON"
        let icon = livestream ? "📡" : "📍"
        let bg = livestream ? Color.lcNavy.opacity(0.10) : Color.lcGoldLight.opacity(0.6)
        let fg: Color = livestream ? .lcNavy : .lcGold
        HStack(spacing: 4) {
            Text(icon).font(.system(size: 10))
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(bg)
        .foregroundColor(fg)
        .clipShape(Capsule())
        .lineLimit(1)
    }

    private var liveNowPill: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.white)
                .frame(width: 5, height: 5)
            Text("LIVE NOW")
                .font(.system(size: 9, weight: .heavy))
                .tracking(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(Color.red)
        .foregroundColor(.white)
        .clipShape(Capsule())
    }
}

/// Empty-state card. Renders separately so callers can choose where it appears.
struct ServiceTimesEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("📅").font(.system(size: 28))
            Text("No service times listed yet.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.lcText)
            Text("Check back soon or visit the church website for more details.")
                .font(.system(size: 12))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    Color.lcBorder,
                    style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
