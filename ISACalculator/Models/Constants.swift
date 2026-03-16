import Foundation

/// Physical constants for the International Standard Atmosphere
enum ISAConstants {
    // MARK: - Sea Level Reference Values
    static let T0: Double = 288.15        // K — sea level standard temperature
    static let P0: Double = 101_325.0     // Pa — sea level standard pressure
    static let rho0: Double = 1.225       // kg/m³ — sea level standard density

    // MARK: - Physical Constants
    static let g0: Double = 9.80665       // m/s² — standard gravity
    static let R: Double = 287.05287      // J/(kg·K) — specific gas constant for dry air
    static let gamma: Double = 1.4        // ratio of specific heats for dry air
    static let rEarth: Double = 6_356_766 // m — effective earth radius (geopotential model)

    // MARK: - Sutherland's Law Constants
    static let muRef: Double = 1.458e-6   // kg/(m·s·K^0.5) — Sutherland reference
    static let sutherlandS: Double = 110.4 // K — Sutherland temperature

    // MARK: - Atmosphere Layer Definitions
    // Each layer: (base altitude [m], base temperature [K], lapse rate [K/m])
    static let layers: [(hBase: Double, tBase: Double, lapse: Double)] = [
        (0,      288.15, -0.0065),   // Troposphere
        (11_000, 216.65,  0.0),      // Tropopause
        (20_000, 216.65,  0.001),    // Stratosphere lower
        (32_000, 228.65,  0.0028),   // Stratosphere upper
        (47_000, 270.65,  0.0),      // Stratopause
        (51_000, 270.65, -0.0028),   // Mesosphere lower
    ]

    /// Upper boundary of the modeled atmosphere (m)
    static let maxAltitude: Double = 51_000

    // MARK: - Conversion Factors
    static let feetPerMeter: Double = 3.28084
    static let meterPerFoot: Double = 0.3048
    static let hPaPerPa: Double = 0.01
    static let inHgPerPa: Double = 0.000295300
    static let mphPerMs: Double = 2.23694
    static let knotsPerMs: Double = 1.94384
}
