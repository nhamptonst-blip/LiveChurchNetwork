import Foundation

// Pure-functional helpers for ServiceTime / OfficeHours.
// 1:1 port of src/lib/schedule.ts in the lcn-web codebase so iOS and web
// behave identically when reading the same JSONB columns.

enum ScheduleHelpers {

    // MARK: - Time formatting

    /// "09:00" -> "9:00 AM"
    static func formatTime12h(_ hhmm: String?) -> String {
        guard let hhmm, !hhmm.isEmpty else { return "" }
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1])
        else { return hhmm }
        let period = h >= 12 ? "PM" : "AM"
        let hour12 = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", hour12, m, period)
    }

    /// "09:00" + "10:30" -> "9:00 AM – 10:30 AM"
    /// "09:00" + "09:00" -> "9:00 AM"  (treats matching ends as no end)
    static func formatTimeRange(_ start: String, _ end: String?) -> String {
        guard !start.isEmpty else { return "" }
        guard let end, !end.isEmpty, end != start else { return formatTime12h(start) }
        return "\(formatTime12h(start)) – \(formatTime12h(end))"
    }

    static func toMinutes(_ hhmm: String) -> Int? {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1])
        else { return nil }
        return h * 60 + m
    }

    // MARK: - Grouping

    static func groupByDay(_ services: [ServiceTime]) -> [(day: DayOfWeek, entries: [ServiceTime])] {
        var bucket: [DayOfWeek: [ServiceTime]] = [:]
        for s in services {
            bucket[s.day, default: []].append(s)
        }
        return DayOfWeek.allCases
            .filter { bucket[$0] != nil }
            .map { day in
                (day, (bucket[day] ?? []).sorted { $0.startTime < $1.startTime })
            }
    }

    // MARK: - Live now

    /// Returns the service currently in progress, if any.
    /// Naive: uses local time. When `schedule_timezone` is honored later,
    /// switch to a TimeZone-aware Calendar.
    static func findLiveService(_ services: [ServiceTime], now: Date = Date()) -> ServiceTime? {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: now) // 1 = Sunday
        let day = DayOfWeek.allCases[(weekday - 1) % 7]
        let minutes = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
        for s in services where s.day == day {
            guard let start = toMinutes(s.startTime),
                  let end = toMinutes(s.endTime)
            else { continue }
            let endEffective = end > start ? end : start + 60
            if minutes >= start && minutes < endEffective {
                return s
            }
        }
        return nil
    }

    // MARK: - Office hours run-collapse

    struct OfficeHoursRow: Hashable, Identifiable {
        var id: String { label + value }
        let days: [DayOfWeek]
        let label: String   // "Mon–Fri" or "Sunday"
        let value: String   // "9:00 AM – 5:00 PM" or "Closed"
    }

    static func collapseRuns(_ hours: OfficeHours) -> [OfficeHoursRow] {
        var rows: [OfficeHoursRow] = []
        var runDays: [DayOfWeek] = []
        var runKey = ""

        let flush = {
            guard let first = runDays.first else { return }
            let day = hours.schedule[first.rawValue] ?? OfficeHoursDay(isOpen: false, open: nil, close: nil)
            let value: String
            if day.isOpen, let open = day.open, let close = day.close {
                value = "\(formatTime12h(open)) – \(formatTime12h(close))"
            } else {
                value = "Closed"
            }
            let label = runDays.count == 1
                ? first.label
                : "\(first.shortLabel)–\(runDays.last!.shortLabel)"
            rows.append(OfficeHoursRow(days: runDays, label: label, value: value))
        }

        for day in DayOfWeek.allCases {
            let d = hours.schedule[day.rawValue] ?? OfficeHoursDay(isOpen: false, open: nil, close: nil)
            let key = d.isOpen ? "\(d.open ?? "")-\(d.close ?? "")" : "closed"
            if key != runKey {
                flush()
                runDays = [day]
                runKey = key
            } else {
                runDays.append(day)
            }
        }
        flush()
        return rows
    }

    // MARK: - Legacy text parser

    private static let dayPatterns: [(DayOfWeek, NSRegularExpression)] = {
        let patterns: [(DayOfWeek, String)] = [
            (.sunday,    #"\bsun(?:day)?s?\b"#),
            (.monday,    #"\bmon(?:day)?s?\b"#),
            (.tuesday,   #"\btues?(?:day)?s?\b"#),
            (.wednesday, #"\bwed(?:nesday)?s?\b"#),
            (.thursday,  #"\bthu(?:rs?(?:day)?)?s?\b"#),
            (.friday,    #"\bfri(?:day)?s?\b"#),
            (.saturday,  #"\bsat(?:urday)?s?\b"#),
        ]
        return patterns.compactMap { (day, p) in
            guard let re = try? NSRegularExpression(pattern: p, options: [.caseInsensitive]) else { return nil }
            return (day, re)
        }
    }()

    private static let timeRegex: NSRegularExpression = {
        let pattern = #"\b(1[0-2]|0?[1-9])(?::([0-5]\d))?\s*([ap])\.?m\.?\b|\b([01]?\d|2[0-3]):([0-5]\d)\b"#
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()

    private struct ExtractedTime {
        let hh: Int
        let mm: Int
    }

    private static func extractTimes(in line: String) -> [ExtractedTime] {
        let range = NSRange(line.startIndex..., in: line)
        var out: [ExtractedTime] = []
        timeRegex.enumerateMatches(in: line, range: range) { match, _, _ in
            guard let match else { return }
            // Group indices: 1=12h hour, 2=12h minutes, 3=am/pm, 4=24h hour, 5=24h minutes
            if let g3 = nsRangeText(match.range(at: 3), in: line) {
                let h12 = Int(nsRangeText(match.range(at: 1), in: line) ?? "") ?? 0
                let mins = Int(nsRangeText(match.range(at: 2), in: line) ?? "0") ?? 0
                let isPm = g3.lowercased() == "p"
                let hh = isPm ? (h12 == 12 ? 12 : h12 + 12) : (h12 == 12 ? 0 : h12)
                out.append(ExtractedTime(hh: hh, mm: mins))
            } else if let g4 = nsRangeText(match.range(at: 4), in: line) {
                let hh = Int(g4) ?? 0
                let mm = Int(nsRangeText(match.range(at: 5), in: line) ?? "0") ?? 0
                out.append(ExtractedTime(hh: hh, mm: mm))
            }
        }
        return out
    }

    private static func nsRangeText(_ range: NSRange, in source: String) -> String? {
        guard range.location != NSNotFound, let r = Range(range, in: source) else { return nil }
        return String(source[r])
    }

    /// Best-effort parser for legacy `service_times` text such as
    /// "Sundays 9:00 AM & 11:00 AM\nWednesdays 7pm" or "tuesdays 6Pm".
    /// Returns [] if nothing recognizable was found.
    static func parseLegacyServiceTimes(_ raw: String?) -> [ServiceTime] {
        guard let raw, !raw.isEmpty else { return [] }
        let lines = raw
            .components(separatedBy: CharacterSet(charactersIn: "\n;•"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var out: [ServiceTime] = []
        for line in lines {
            // Days mentioned on this line
            let days = dayPatterns.compactMap { (day, re) -> DayOfWeek? in
                let r = NSRange(line.startIndex..., in: line)
                return re.firstMatch(in: line, range: r) != nil ? day : nil
            }
            guard !days.isEmpty else { continue }

            let times = extractTimes(in: line)
            guard !times.isEmpty else { continue }

            // Strip days + times to find a service-type label
            var label = line
            for (_, re) in dayPatterns {
                let r = NSRange(label.startIndex..., in: label)
                label = re.stringByReplacingMatches(in: label, range: r, withTemplate: "")
            }
            let r = NSRange(label.startIndex..., in: label)
            label = timeRegex.stringByReplacingMatches(in: label, range: r, withTemplate: "")
            let cleaned = label
                .replacingOccurrences(of: "&", with: " ")
                .replacingOccurrences(of: ",", with: " ")
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
                .trimmingCharacters(in: CharacterSet(charactersIn: " \t-:·•"))
            let serviceType = cleaned.count > 1 ? capitalizeWords(cleaned) : "Service"

            for day in days {
                for t in times {
                    let start = String(format: "%02d:%02d", t.hh, t.mm)
                    out.append(ServiceTime(
                        id: UUID().uuidString,
                        serviceType: serviceType,
                        day: day,
                        startTime: start,
                        endTime: start,
                        language: "English",
                        livestream: false
                    ))
                }
            }
        }
        return out
    }

    private static func capitalizeWords(_ s: String) -> String {
        s.lowercased()
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    // MARK: - Summaries (kept in sync with legacy text columns)

    /// Auto-derives the human-readable string for `service_times` so external
    /// readers (iOS legacy clients, integrations) keep working.
    static func summarizeServiceTimes(_ services: [ServiceTime]) -> String {
        guard !services.isEmpty else { return "" }
        return groupByDay(services).map { (day, entries) -> String in
            let times = entries.map { e -> String in
                let range = formatTimeRange(e.startTime, e.endTime)
                let tag = (!e.serviceType.isEmpty && e.serviceType != "Sunday Service")
                    ? " (\(e.serviceType))" : ""
                return "\(range)\(tag)"
            }.joined(separator: ", ")
            return "\(day.label): \(times)"
        }.joined(separator: "\n")
    }

    static func summarizeOfficeHours(_ hours: OfficeHours) -> String {
        if hours.byAppointmentOnly { return "By appointment only" }
        let rows = collapseRuns(hours)
        return rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n")
    }

    // MARK: - Defaults

    /// Reasonable starter office hours: weekdays 9–5, weekends closed.
    static var emptyOfficeHours: OfficeHours {
        let closed = OfficeHoursDay(isOpen: false, open: nil, close: nil)
        let weekday = OfficeHoursDay(isOpen: true, open: "09:00", close: "17:00")
        return OfficeHours(
            byAppointmentOnly: false,
            schedule: [
                "sunday":    closed,
                "monday":    weekday,
                "tuesday":   weekday,
                "wednesday": weekday,
                "thursday":  weekday,
                "friday":    weekday,
                "saturday":  closed
            ]
        )
    }
}
