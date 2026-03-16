import Foundation
import Observation

@Observable
final class AtmosphereViewModel {

    // MARK: - Input State

    var altitudeInput: Double = 0 {
        didSet { recompute() }
    }

    var altitudeText: String = "0" {
        didSet {
            if let val = Double(altitudeText), val != altitudeInput {
                altitudeInput = val
            }
        }
    }

    var altitudeUnit: AltitudeUnit = .meters {
        didSet {
            // Convert current altitude to the new unit
            if oldValue != altitudeUnit {
                switch altitudeUnit {
                case .meters:
                    altitudeInput = altitudeInput * ISAConstants.meterPerFoot
                case .feet:
                    altitudeInput = altitudeInput * ISAConstants.feetPerMeter
                }
                altitudeText = String(format: "%.0f", altitudeInput)
            }
        }
    }

    var altitudeType: AltitudeType = .geopotential {
        didSet { recompute() }
    }

    var isaDeviation: Double = 0 {
        didSet {
            recompute()
            scheduleProfileGeneration()
        }
    }

    // MARK: - Density Altitude Inputs

    var densityPressureAltitudeFt: Double = 0
    var densityOATCelsius: Double = 15.0

    // MARK: - Computed Outputs

    private(set) var currentState: AtmosphereState = .seaLevel
    private(set) var densityAltitudeResult: Double = 0
    private(set) var densityAltitudeISATemp: Double = 15.0
    private(set) var profileData: [AtmosphereState] = []

    // MARK: - Live Sensor State

    var livePressureHPa: Double? = nil
    var livePressureAltitude: Double? = nil
    var gpsAltitude: Double? = nil
    var sensorError: String? = nil

    // MARK: - Services

    let altimeterService = AltimeterService()
    let locationService = LocationService()

    // MARK: - Private

    private var profileGenerationTask: DispatchWorkItem?

    // MARK: - Init

    init() {
        recompute()
        generateProfile()
    }

    // MARK: - Computation

    func recompute() {
        let geopotentialAlt = geopotentialAltitudeMeters()
        currentState = ISAComputer.compute(altitude: geopotentialAlt, isaDeviation: isaDeviation)
    }

    func computeDensityAltitude() {
        let paMeters = densityPressureAltitudeFt * ISAConstants.meterPerFoot
        let oatK = densityOATCelsius + 273.15
        densityAltitudeResult = ISAComputer.densityAltitude(
            pressureAltitude: paMeters,
            oatKelvin: oatK
        )
        // ISA temp at the pressure altitude
        let isaState = ISAComputer.compute(altitude: paMeters)
        densityAltitudeISATemp = isaState.temperatureC
    }

    func generateProfile() {
        profileData = ISAComputer.profile(step: 500, isaDeviation: isaDeviation)
    }

    /// Debounce profile generation to avoid regenerating on every small slider change
    private func scheduleProfileGeneration() {
        profileGenerationTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.generateProfile()
        }
        profileGenerationTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: task)
    }

    // MARK: - Live Sensor

    func startLiveSensors() {
        sensorError = nil

        altimeterService.startUpdates { [weak self] pressurePa in
            guard let self else { return }
            let hPa = pressurePa * ISAConstants.hPaPerPa
            self.livePressureHPa = hPa
            self.livePressureAltitude = ISAComputer.pressureAltitude(pressure: pressurePa)
        }

        locationService.startUpdates { [weak self] altitude in
            guard let self else { return }
            self.gpsAltitude = altitude
        } onError: { [weak self] error in
            guard let self else { return }
            self.sensorError = error.localizedDescription
        }
    }

    func stopLiveSensors() {
        altimeterService.stopUpdates()
        locationService.stopUpdates()
        sensorError = nil
    }

    // MARK: - Helpers

    /// Converts the current input altitude to geopotential meters
    func geopotentialAltitudeMeters() -> Double {
        var altMeters = altitudeInput
        if altitudeUnit == .feet {
            altMeters = altitudeInput * ISAConstants.meterPerFoot
        }

        if altitudeType == .geometric {
            altMeters = ISAComputer.geometricToGeopotential(altMeters)
        }

        return altMeters
    }

    /// Sets the altitude from a chart drag (always in geopotential meters)
    func setAltitudeFromChart(_ altMeters: Double) {
        if altitudeUnit == .feet {
            altitudeInput = altMeters * ISAConstants.feetPerMeter
        } else {
            altitudeInput = altMeters
        }
        altitudeText = String(format: "%.0f", altitudeInput)
    }

    /// Formatted altitude display
    var formattedAltitude: String {
        String(format: "%.0f %@", altitudeInput, altitudeUnit.rawValue)
    }
}
