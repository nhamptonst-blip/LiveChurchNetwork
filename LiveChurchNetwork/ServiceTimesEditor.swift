import SwiftUI

/// Repeatable cards editor for `[ServiceTime]`. Each card lets the church
/// admin pick service type, day, start/end time, language, and toggle
/// livestreaming. Add Service Time button appends a new entry; remove
/// button removes a single card.
///
/// 1:1 functional port of web's <ServiceTimesEditor/>.
struct ServiceTimesEditor: View {
    @Binding var services: [ServiceTime]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if services.isEmpty {
                emptyState
            } else {
                ForEach(services.indices, id: \.self) { idx in
                    ServiceTimeCard(
                        index: idx + 1,
                        service: $services[idx],
                        onRemove: { services.remove(at: idx) }
                    )
                }
            }

            Button(action: addService) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add Service Time")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.lcNavy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            Color.lcNavy.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [5, 4])
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("No service times yet.")
                .font(.system(size: 14))
                .foregroundColor(.lcText3)
            Text("Add at least one so worshippers know when to attend.")
                .font(.system(size: 12))
                .foregroundColor(.lcText3.opacity(0.8))
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

    private func addService() {
        services.append(ServiceTime(
            id: UUID().uuidString,
            serviceType: "Sunday Service",
            day: .sunday,
            startTime: "09:00",
            endTime: "10:30",
            language: "English",
            livestream: false
        ))
    }
}

// MARK: - Single card

private struct ServiceTimeCard: View {
    let index: Int
    @Binding var service: ServiceTime
    let onRemove: () -> Void

    static let serviceTypeOptions = [
        "Sunday Service", "Saturday Service", "Wednesday Service",
        "Bible Study", "Prayer Meeting", "Youth Group", "Small Group",
        "Worship Night", "Kids Ministry", "Other"
    ]

    static let languageOptions = [
        "English", "Spanish", "Portuguese", "French", "Korean", "Mandarin",
        "Cantonese", "Vietnamese", "Tagalog", "Arabic", "Russian"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SERVICE #\(index)")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.lcText3)
                Spacer()
                Button("Remove", action: onRemove)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red)
            }

            // Service type + day
            HStack(spacing: 8) {
                fieldLabel("Service Type")
                Spacer()
                Picker("", selection: $service.serviceType) {
                    ForEach(Self.serviceTypeOptions, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            HStack(spacing: 8) {
                fieldLabel("Day")
                Spacer()
                Picker("", selection: $service.day) {
                    ForEach(DayOfWeek.allCases, id: \.self) { d in
                        Text(d.label).tag(d)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            // Times
            HStack(spacing: 8) {
                fieldLabel("Start")
                Spacer()
                TimePicker(value: $service.startTime)
            }
            HStack(spacing: 8) {
                fieldLabel("End")
                Spacer()
                TimePicker(value: $service.endTime)
            }

            // Language
            HStack(spacing: 8) {
                fieldLabel("Language")
                Spacer()
                Picker("", selection: $service.language) {
                    ForEach(Self.languageOptions, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            // Livestream toggle
            Toggle(isOn: $service.livestream) {
                Text(service.livestream ? "Streamed online" : "In-person only")
                    .font(.system(size: 13))
                    .foregroundColor(.lcText2)
            }
            .tint(.lcNavy)
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.lcText2)
    }
}

// MARK: - Time picker (HH:mm string <-> Date)

private struct TimePicker: View {
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
