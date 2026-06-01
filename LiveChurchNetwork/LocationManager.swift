import CoreLocation
import Combine
import UIKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let manager = CLLocationManager()

    @Published var userLocation: CLLocation? = nil
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var userCity: String? = nil

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    /// Request When-In-Use authorization. If the user has already denied,
    /// the system dialog will NOT show again — iOS only prompts once. In
    /// that case we bounce them to the app's Settings page so they can
    /// flip the toggle, otherwise the "Enable Location" button appears
    /// dead (which is the bug we shipped before).
    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            openAppSettings()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        @unknown default:
            manager.requestWhenInUseAuthorization()
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
        reverseGeocode(location: locations.last)
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    private func reverseGeocode(location: CLLocation?) {
        guard let location else { return }
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            self?.userCity = placemarks?.first?.locality
        }
    }
}
