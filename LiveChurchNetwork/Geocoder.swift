import CoreLocation
import Foundation

/// Resolves a free-form or structured postal address into latitude/longitude
/// using Apple's `CLGeocoder`. Used by the church save paths (onboarding +
/// admin edit) so newly-entered addresses populate `latitude` / `longitude`
/// on `church_submissions`, which is what the Discover "Near You" radius
/// filter requires.
///
/// Why we do this inline at save-time instead of relying solely on the
/// server-side backfill: the backfill is a periodic catchall, and a brand
/// new church should be searchable immediately after submission, not on the
/// next backfill window.
enum Geocoder {
    /// Geocode a postal address. Returns nil on any failure (rate-limit,
    /// no network, ambiguous address) — callers should save the row
    /// anyway and let the periodic backfill resolve coords later.
    static func geocode(
        addressLine: String? = nil,
        city: String? = nil,
        state: String? = nil,
        postalCode: String? = nil,
        country: String? = nil
    ) async -> (latitude: Double, longitude: Double)? {
        let parts = [addressLine, city, state, postalCode, country]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        // Need at least *some* sub-country detail. A query of just "USA"
        // would resolve to the geographic centroid — worse than null.
        let subCountry = [addressLine, city, state, postalCode]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .contains { !$0.isEmpty }
        guard subCountry, !parts.isEmpty else { return nil }
        let query = parts.joined(separator: ", ")
        return await geocode(freeform: query)
    }

    /// Geocode a single free-form address string (e.g. what the onboarding
    /// step asks for: `123 Main St, Nashville, TN 37201`).
    static func geocode(freeform: String) async -> (latitude: Double, longitude: Double)? {
        let trimmed = freeform.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        do {
            let placemarks = try await CLGeocoder().geocodeAddressString(trimmed)
            guard let coord = placemarks.first?.location?.coordinate else { return nil }
            return (coord.latitude, coord.longitude)
        } catch {
            return nil
        }
    }
}
