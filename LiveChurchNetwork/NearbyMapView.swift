import SwiftUI
import MapKit
import CoreLocation

/// Map showing the user's location plus pins for every nearby church the
/// caller has already filtered by radius. Replaces the "Map view coming
/// soon" placeholder. Tapping a pin pushes the church profile.
///
/// We pass in the pre-filtered `churches` list so the map and the list
/// view stay in lock-step — the radius slider and sort selection on the
/// outer view drive both.
struct NearbyMapView: View {
    let userLocation: CLLocation
    let radiusMiles: Double
    let churches: [Church]

    @State private var region: MKCoordinateRegion
    @State private var selectedChurch: Church? = nil

    init(userLocation: CLLocation, radiusMiles: Double, churches: [Church]) {
        self.userLocation = userLocation
        self.radiusMiles = radiusMiles
        self.churches = churches
        // Span scaled to roughly fit the radius. 1 degree latitude ≈ 69mi
        // so the span is radius / 69 doubled (north + south). Loose, but
        // good enough as an initial framing.
        let span = max(0.05, (radiusMiles * 2.2) / 69.0)
        _region = State(initialValue: MKCoordinateRegion(
            center: userLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        ))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: churches) { church in
                MapAnnotation(coordinate: coordinate(for: church)) {
                    Button {
                        selectedChurch = church
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: church.isLive ? "dot.radiowaves.left.and.right" : "building.2.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(church.isLive ? Color.red : Color(red: 31/255, green: 60/255, blue: 136/255))
                                )
                                .shadow(color: Color.black.opacity(0.18), radius: 3, x: 0, y: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 22))

            // Recenter button — easy escape if the user has panned away
            Button {
                let span = max(0.05, (radiusMiles * 2.2) / 69.0)
                withAnimation(.easeInOut(duration: 0.3)) {
                    region = MKCoordinateRegion(
                        center: userLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
                    )
                }
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .padding(12)
        }
        .padding(.horizontal, 20)
        .sheet(item: $selectedChurch) { church in
            NavigationStack {
                ChurchDetailView(church: church)
            }
        }
    }

    private func coordinate(for church: Church) -> CLLocationCoordinate2D {
        // Filtered list is guaranteed to have lat/lng but the optional
        // accessors keep the type-checker honest; fall back to the user
        // location so a stray nil never crashes the map.
        CLLocationCoordinate2D(
            latitude: church.latitude ?? userLocation.coordinate.latitude,
            longitude: church.longitude ?? userLocation.coordinate.longitude,
        )
    }
}
