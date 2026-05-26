import SwiftUI

/// Public-profile office hours card. Collapses identical consecutive days
/// (e.g. "Mon–Fri 9:00 AM – 5:00 PM"). Highlights today's row in gold.
///
/// 1:1 visual port of the web app's <OfficeHoursDisplay/> component.
struct OfficeHoursDisplay: View {
    let hours: OfficeHours
    var now: Date? = Date()

    var body: some View {
        if hours.byAppointmentOnly {
            byAppointmentCard
        } else {
            collapsedRowsCard
        }
    }

    private var byAppointmentCard: some View {
        HStack(spacing: 6) {
            Text("By appointment only")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.lcText)
            Text("· contact the church to schedule a visit.")
                .font(.system(size: 14))
                .foregroundColor(.lcText3)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.lcCream.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var collapsedRowsCard: some View {
        let rows = ScheduleHelpers.collapseRuns(hours)
        let todayKey = todayDayOfWeek()

        return VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                let includesToday = todayKey != nil && row.days.contains(todayKey!)
                HStack {
                    Text(row.label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(includesToday ? .lcText : .lcText2)
                    Spacer()
                    Text(row.value)
                        .font(.system(size: 14, weight: includesToday ? .semibold : .regular))
                        .foregroundColor(includesToday ? .lcText : .lcText3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(includesToday ? Color.lcGoldLight.opacity(0.4) : Color.clear)

                if idx < rows.count - 1 {
                    Divider().background(Color.lcBorder)
                }
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func todayDayOfWeek() -> DayOfWeek? {
        guard let now else { return nil }
        // Calendar.weekday: 1 = Sunday … 7 = Saturday
        let weekday = Calendar.current.component(.weekday, from: now)
        return DayOfWeek.allCases[(weekday - 1) % 7]
    }
}
