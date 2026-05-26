import SwiftUI

/// Weekly grid editor for `OfficeHours`. Per-day Open/Closed toggle, open
/// + close time pickers, "Apply Mon–Fri" quick action, and "By Appointment
/// Only" mode that hides the grid.
///
/// 1:1 functional port of web's <OfficeHoursEditor/>.
struct OfficeHoursEditor: View {
    @Binding var hours: OfficeHours

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            quickActionsRow
            if hours.byAppointmentOnly {
                byAppointmentCard
            } else {
                weeklyGrid
            }
        }
    }

    // MARK: - Quick actions

    private var quickActionsRow: some View {
        HStack(spacing: 8) {
            Button("Apply Mon–Fri", action: applyMonFri)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.lcNavy)
                .disabled(hours.byAppointmentOnly)

            Button("Close all days", action: closeAllDays)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.lcText2)
                .disabled(hours.byAppointmentOnly)

            Spacer()

            Toggle(isOn: $hours.byAppointmentOnly) {
                Text("By Appointment Only")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.lcText2)
            }
            .toggleStyle(.switch)
            .labelsHidden()
            .tint(.lcNavy)
        }
    }

    // MARK: - By appointment

    private var byAppointmentCard: some View {
        VStack(spacing: 6) {
            Text("By Appointment Only")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.lcText)
            Text("Members will see \"Contact for an appointment\" on your public profile.")
                .font(.system(size: 12))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Color.lcCream.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.lcBorder, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                get: { binding.wrappedValue.isOpen },
                set: { newVal in
                    var d = binding.wrappedValue
                    d.isOpen = newVal
                    if newVal {
                        if d.open == nil { d.open = "09:00" }
                        if d.close == nil { d.close = "17:00" }
                    } else {
                        d.open = nil
                        d.close = nil
                    }
                    binding.wrappedValue = d
                }
            )) {
                Text(binding.wrappedValue.isOpen ? "Open" : "Closed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.lcText2)
            }
            .toggleStyle(.switch)
            .labelsHidden()
            .tint(.lcNavy)

            Spacer()

            if binding.wrappedValue.isOpen {
                HStack(spacing: 6) {
                    HHMMField(value: Binding(
                        get: { binding.wrappedValue.open ?? "09:00" },
                        set: { v in
                            var d = binding.wrappedValue
                            d.open = v
                            binding.wrappedValue = d
                        }
                    ))
                    Text("to").font(.system(size: 11)).foregroundColor(.lcText3)
                    HHMMField(value: Binding(
                        get: { binding.wrappedValue.close ?? "17:00" },
                        set: { v in
                            var d = binding.wrappedValue
                            d.close = v
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

    private func applyMonFri() {
        let monday = hours.schedule["monday"] ?? OfficeHoursDay(isOpen: true, open: "09:00", close: "17:00")
        let open = monday.open ?? "09:00"
        let close = monday.close ?? "17:00"
        var sched = hours.schedule
        for day in ["monday", "tuesday", "wednesday", "thursday", "friday"] {
            sched[day] = OfficeHoursDay(isOpen: true, open: open, close: close)
        }
        hours = OfficeHours(byAppointmentOnly: false, schedule: sched)
    }

    private func closeAllDays() {
        var sched = hours.schedule
        for day in DayOfWeek.allCases {
            sched[day.rawValue] = OfficeHoursDay(isOpen: false, open: nil, close: nil)
        }
        hours = OfficeHours(byAppointmentOnly: false, schedule: sched)
    }

    // MARK: - Per-day binding

    private func dayBinding(_ day: DayOfWeek) -> Binding<OfficeHoursDay> {
        Binding(
            get: { hours.schedule[day.rawValue] ?? OfficeHoursDay(isOpen: false, open: nil, close: nil) },
            set: { newVal in
                var sched = hours.schedule
                sched[day.rawValue] = newVal
                hours = OfficeHours(byAppointmentOnly: hours.byAppointmentOnly, schedule: sched)
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
                get: { dateFromHHMM(value) ?? Calendar.current.date(from: DateComponents(hour: 9))! },
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
