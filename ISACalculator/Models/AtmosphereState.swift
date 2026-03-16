import Foundation

/// Complete atmospheric state at a given altitude
struct AtmosphereState: Identifiable, Equatable, Sendable {
    /// Unique identifier based on altitude for SwiftUI list/chart performance
    var id: Double { altitude }
    /// Geopotential altitude (m)
    let altitude: Double
    /// Temperature (K)
    let temperature: Double
    /// Pressure (Pa)
    let pressure: Double
    /// Density (kg/m³)
    let density: Double
    /// Speed of sound (m/s)
    let speedOfSound: Double
    /// Dynamic viscosity (Pa·s)
    let dynamicViscosity: Double
    /// Kinematic viscosity (m²/s)
    let kinematicViscosity: Double

    // MARK: - Derived Ratios

    var temperatureRatio: Double { temperature / ISAConstants.T0 }
    var pressureRatio: Double { pressure / ISAConstants.P0 }
    var densityRatio: Double { density / ISAConstants.rho0 }

    // MARK: - Imperial Conversions

    var temperatureF: Double { (temperature - 273.15) * 9.0 / 5.0 + 32.0 }
    var temperatureC: Double { temperature - 273.15 }
    var pressureHPa: Double { pressure * ISAConstants.hPaPerPa }
    var pressureInHg: Double { pressure * ISAConstants.inHgPerPa }
    var altitudeFt: Double { altitude * ISAConstants.feetPerMeter }
    var speedOfSoundKnots: Double { speedOfSound * ISAConstants.knotsPerMs }
    var speedOfSoundMph: Double { speedOfSound * ISAConstants.mphPerMs }

    // MARK: - Layer Info

    var layerName: String {
        switch altitude {
        case ..<11_000: return "Troposphere"
        case ..<20_000: return "Tropopause"
        case ..<32_000: return "Lower Stratosphere"
        case ..<47_000: return "Upper Stratosphere"
        default: return "Stratopause"
        }
    }

    // MARK: - Sea Level Reference

    static let seaLevel = ISAComputer.compute(altitude: 0)
}

// MARK: - Altitude & Unit Types

enum AltitudeUnit: String, CaseIterable, Identifiable {
    case meters = "m"
    case feet = "ft"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .meters: return String(localized: "Meters")
        case .feet: return String(localized: "Feet")
        }
    }

    var maxSlider: Double {
        switch self {
        case .meters: return 51_000
        case .feet: return 51_000 * ISAConstants.feetPerMeter
        }
    }
}

enum AltitudeType: String, CaseIterable, Identifiable {
    case geometric
    case geopotential

    var id: String { rawValue }

    var label: String {
        switch self {
        case .geometric: return String(localized: "Geometric")
        case .geopotential: return String(localized: "Geopotential")
        }
    }
}

/// Which atmospheric property to display on the chart
enum AtmosphereProperty: String, CaseIterable, Identifiable {
    case temperature
    case pressure
    case density
    case speedOfSound

    var id: String { rawValue }

    var label: String {
        switch self {
        case .temperature: return String(localized: "Temperature")
        case .pressure: return String(localized: "Pressure Ratio")
        case .density: return String(localized: "Density Ratio")
        case .speedOfSound: return String(localized: "Speed of Sound")
        }
    }

    var unit: String {
        switch self {
        case .temperature: return "K"
        case .pressure: return "P/P₀"
        case .density: return "ρ/ρ₀"
        case .speedOfSound: return "m/s"
        }
    }

    var color: String {
        switch self {
        case .temperature: return "red"
        case .pressure: return "blue"
        case .density: return "green"
        case .speedOfSound: return "orange"
        }
    }

    func value(from state: AtmosphereState) -> Double {
        switch self {
        case .temperature: return state.temperature
        case .pressure: return state.pressureRatio
        case .density: return state.densityRatio
        case .speedOfSound: return state.speedOfSound
        }
    }
}
