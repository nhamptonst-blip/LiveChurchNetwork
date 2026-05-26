import Foundation

// Single source of truth for "is this church live right now?" — mirrors the
// web helper at lcn-web/src/lib/is-church-actually-live.ts.
//
// Resolution order:
//   1. Manual override (`is_live = true`) wins. The Go Live button lets a
//      church admin force the badge on for unscheduled streams.
//   2. Scheduled service window — derived from `service_times_json`
//      evaluated against the current time *in the church's timezone*.
//      The full window counts: start-time-inclusive, end-time-exclusive.
//
// We deliberately do *not* check `livestreamUrl`. The badge means "they're
// in service right now"; the watch button is gated separately by URL.

enum LiveChurchEvaluator {

    static func isLiveNow(
        _ church: ChurchSubmission,
        now: Date = Date(),
        ignoreManualOverride: Bool = false
    ) -> Bool {
        // Manual override always wins (unless the caller explicitly wants
        // pure schedule-derived signal — e.g. the church admin's dashboard
        // disambiguating "manual" vs "scheduled" live state).
        if !ignoreManualOverride && church.isLive { return true }

        guard let services = church.serviceTimesJson, !services.isEmpty else {
            return false
        }
        return isCurrentlyInWindow(
            services: services,
            timezone: church.scheduleTimezone,
            now: now,
        )
    }

    // MARK: Time-zone-aware "now"

    private static func isCurrentlyInWindow(
        services: [ServiceTime],
        timezone tzId: String?,
        now: Date,
    ) -> Bool {
        let tz = tzId.flatMap(TimeZone.init(identifier:)) ?? TimeZone.current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz

        let comps = calendar.dateComponents([.weekday, .hour, .minute], from: now)
        guard let weekday = comps.weekday, // 1 = Sunday
              let hour    = comps.hour,
              let minute  = comps.minute else { return false }

        let dayString = ["sunday", "monday", "tuesday", "wednesday",
                         "thursday", "friday", "saturday"][weekday - 1]
        let nowMinutes = hour * 60 + minute

        for service in services where service.day.rawValue.lowercased() == dayString {
            guard let start = toMinutes(service.startTime),
                  let end   = toMinutes(service.endTime) else { continue }
            // If endTime equals startTime the editor uses that to mean
            // "no end" — treat as a 60-minute window so the badge isn't
            // stuck on forever and isn't off the same instant the service
            // starts.
            let effectiveEnd = end > start ? end : start + 60
            if nowMinutes >= start && nowMinutes < effectiveEnd {
                return true
            }
        }
        return false
    }

    private static func toMinutes(_ hhmm: String) -> Int? {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return nil }
        return h * 60 + m
    }
}
