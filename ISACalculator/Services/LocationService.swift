import Foundation
import CoreLocation

/// Wraps CLLocationManager to provide GPS altitude
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var updateHandler: ((Double) -> Void)?
    private var errorHandler: ((Error) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// Start receiving GPS altitude updates
    /// - Parameters:
    ///   - handler: Called with altitude in meters on each update
    ///   - onError: Called when location updates fail (optional)
    func startUpdates(handler: @escaping (Double) -> Void, onError: ((Error) -> Void)? = nil) {
        self.updateHandler = handler
        self.errorHandler = onError
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    /// Stop GPS updates
    func stopUpdates() {
        manager.stopUpdatingLocation()
        updateHandler = nil
        errorHandler = nil
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        updateHandler?(location.altitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorHandler?(error)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied, .restricted:
            let error = NSError(
                domain: "LocationService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Location permission denied"]
            )
            errorHandler?(error)
        default:
            break
        }
    }
}
