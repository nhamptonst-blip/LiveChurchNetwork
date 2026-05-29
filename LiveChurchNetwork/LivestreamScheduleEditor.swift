import SwiftUI

/// Weekly grid editor for `LivestreamSchedule` — the days/times a church
/// goes live online (distinct from in-person `ServiceTime`s). Per-day
/// Live/Off-air toggle, start + end time pickers, and "Apply Sunday" /
/// "Clear all days" quick actions.
///
/// Functional port of web's <LivestreamScheduleEditor/>. Mirrors the
/// OfficeHoursEditor grid, but speaks streaming language (Live / Off air)
/// and seeds nothing by default — see ScheduleHelpers.emptyLivestreamSchedule.
struct LivestreamScheduleEditor: View {
    @Binding var schedule: LivestreamSchedule

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            quickActionsRow
            weeklyGrid
        }
    }

    // MARK: - Quick actions

    private var quickActionsRow: some View {
        HStack(spacing: 8) {
            Button("Apply Sunday", action: applySunday)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.lcNavy)

            Button("Clear all days", action: clearAllDays)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.lcText2)

            Spacer()
        }
    }

    // MARK: - Weekly grid

    private var weeklyGrid: some View {
        VStack(spacing: 0) {
            ForEach(Array(DayOfWeek.allCases.enumerated()), id: \.element) { idx, day in
                dayRow(day)
                if idx < DayOfWeek.allCases.count - 1 {
                    Divider().background(Color.lcBorder)
                }
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func dayRow(_ day: DayOfWeek) -> some View {
        let binding = dayBinding(day)
        HStack(spacing: 12) {
            Text(day.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.lcText)
                .frame(width: 90, alignment: .leading)

            Toggle(isOn: Binding(
                get: { binding.wrappedValue.isLive },
                set: { newVal in
                    var d = binding.wrappedValue
                    d.isLive = newVal
                    if newVal {
                        if d.start == nil { d.start = "10:00" }
                        if d.end == nil { d.end = "11:30" }
                    } else {
                        d.start = nil
                        d.end = nil
                    }
                    binding.wrappedValue = d
                }
            )) {
                Text(binding.wrappedValue.isLive ? "Live" : "Off air")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.lcText2)
            }
            .toggleStyle(.switch)
            .labelsHidden()
            .tint(.lcNavy)

            Spacer()

            if binding.wrappedValue.isLive {
                HStack(spacing: 6) {
                    HHMMField(value: Binding(
                        get: { binding.wrappedValue.start ?? "10:00" },
                        set: { v in
                            var d = binding.wrappedValue
                            d.start = v
                            binding.wrappedValue = d
                        }
                    ))
                    Text("to").font(.system(size: 11)).foregroundColor(.lcText3)
                    HHMMField(value: Binding(
                        get: { binding.wrappedValue.end ?? "11:30" },
                        set: { v in
                            var d = binding.wrappedValue
                            d.end = v
                            binding.wrappedValue = d
                        }
                    ))
                }
            } else {
                Text("—").foregroundColor(.lcText3)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Quick action handlers

    private func applySunday() {
        let existing = schedule.schedule["sunday"]
        let start = existing?.start ?? "10:00"
        let end = existing?.end ?? "11:30"
        var sched = schedule.schedule
        sched["sunday"] = LivestreamScheduleDay(isLive: true, start: start, end: end)
        schedule = LivestreamSchedule(schedule: sched)
    }

    private func clearAllDays() {
        var sched = schedule.schedule
        for day in DayOfWeek.allCases {
            sched[day.rawValue] = LivestreamScheduleDay(isLive: false, start: nil, end: nil)
        }
        schedule = LivestreamSchedule(schedule: sched)
    }

    // MARK: - Per-day binding

    private func dayBinding(_ day: DayOfWeek) -> Binding<LivestreamScheduleDay> {
        Binding(
            get: { schedule.schedule[day.rawValue] ?? LivestreamScheduleDay(isLive: false, start: nil, end: nil) },
            set: { newVal in
                var sched = schedule.schedule
                sched[day.rawValue] = newVal
                schedule = LivestreamSchedule(schedule: sched)
            }
        )
    }
}

// MARK: - Compact HH:mm time field

private struct HHMMField: View {
    @Binding var value: String

    var body: some View {
        DatePicker(
            "",
            selection: Binding(
                get: { dateFromHHMM(value) ?? Calendar.current.date(from: DateComponents(hour: 10))! },
                set: { value = hhmmFromDate($0) }
            ),
            displayedComponents: .hourAndMinute
        )
        .labelsHidden()
        .frame(maxWidth: 100)
    }

    private func dateFromHHMM(_ s: String) -> Date? {
        let parts = s.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1])
        else { return nil }
        return Calendar.current.date(from: DateComponents(hour: h, minute: m))
    }

    private func hhmmFromDate(_ d: Date) -> String {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: d)
        return String(format: "%02d:%02d", comps.hour ?? 0, comps.minute ?? 0)
    }
}
