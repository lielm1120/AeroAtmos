import Foundation
import CoreMotion

/// Wraps CMAltimeter to provide live barometric pressure readings
final class AltimeterService {
    private let altimeter = CMAltimeter()
    private var updateHandler: ((Double) -> Void)?

    /// Whether the device supports barometric pressure readings
    static var isAvailable: Bool {
        CMAltimeter.isRelativeAltitudeAvailable()
    }

    /// Start receiving barometric pressure updates
    /// - Parameter handler: Called with pressure in Pascals (not kPa)
    func startUpdates(handler: @escaping (Double) -> Void) {
        guard Self.isAvailable else { return }
        self.updateHandler = handler

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            // CMAltimeter reports pressure in kPa — convert to Pa
            let pressurePa = data.pressure.doubleValue * 1000.0
            self.updateHandler?(pressurePa)
        }
    }

    /// Stop barometric updates and release handler
    func stopUpdates() {
        altimeter.stopRelativeAltitudeUpdates()
        updateHandler = nil
    }
}
