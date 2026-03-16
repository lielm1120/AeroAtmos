import Foundation

/// Core ISA computation engine
/// Implements the ICAO Standard Atmosphere from 0 to 51 km geopotential altitude.
enum ISAComputer {

    // MARK: - Altitude Conversions

    /// Convert geometric altitude to geopotential altitude
    static func geometricToGeopotential(_ hGeometric: Double) -> Double {
        (ISAConstants.rEarth * hGeometric) / (ISAConstants.rEarth + hGeometric)
    }

    /// Convert geopotential altitude to geometric altitude
    static func geopotentialToGeometric(_ hGeopotential: Double) -> Double {
        (ISAConstants.rEarth * hGeopotential) / (ISAConstants.rEarth - hGeopotential)
    }

    // MARK: - Core ISA Computation

    /// Compute atmosphere state at a given geopotential altitude with optional ISA deviation
    /// - Parameters:
    ///   - altitude: Geopotential altitude in meters (0 to 51,000)
    ///   - isaDeviation: Temperature deviation from ISA in Kelvin (default 0)
    /// - Returns: Complete atmospheric state
    static func compute(altitude: Double, isaDeviation: Double = 0) -> AtmosphereState {
        let h = altitude.clamped(to: 0...ISAConstants.maxAltitude)
        let layers = ISAConstants.layers

        // Find the active layer (last layer whose base altitude ≤ h)
        var layerIndex = 0
        for i in 1..<layers.count {
            if h >= layers[i].hBase {
                layerIndex = i
            } else {
                break
            }
        }

        // Compute P and T by integrating through each layer from the ground up
        var T = layers[0].tBase
        var P = ISAConstants.P0

        for i in 0...layerIndex {
            let hBase = layers[i].hBase
            let tBase = layers[i].tBase
            let lapse = layers[i].lapse
            let hTop = (i < layerIndex) ? layers[i + 1].hBase : h

            T = tBase
            let deltaH = hTop - hBase

            if abs(lapse) < 1e-10 {
                // Isothermal layer
                P *= exp(-ISAConstants.g0 * deltaH / (ISAConstants.R * tBase))
            } else {
                // Gradient layer
                let tTop = tBase + lapse * deltaH
                let exponent = -ISAConstants.g0 / (lapse * ISAConstants.R)
                P *= pow(tTop / tBase, exponent)
                T = tTop
            }
        }

        // Apply ISA deviation to temperature (pressure stays on ISA profile)
        let T_actual = T + isaDeviation

        // Density from equation of state: ρ = P / (R·T)
        let rho = P / (ISAConstants.R * T_actual)

        // Speed of sound: a = √(γ·R·T)
        let a = sqrt(ISAConstants.gamma * ISAConstants.R * T_actual)

        // Dynamic viscosity via Sutherland's law: μ = C₁·T^(3/2) / (T + S)
        let mu = ISAConstants.muRef * pow(T_actual, 1.5) / (T_actual + ISAConstants.sutherlandS)

        // Kinematic viscosity: ν = μ / ρ
        let nu = rho > 0 ? mu / rho : 0

        return AtmosphereState(
            altitude: h,
            temperature: T_actual,
            pressure: P,
            density: rho,
            speedOfSound: a,
            dynamicViscosity: mu,
            kinematicViscosity: nu
        )
    }

    // MARK: - Pressure Altitude (Back-Solve)

    /// Given a measured pressure, find the ISA altitude that produces that pressure.
    /// Uses bisection method for robustness.
    static func pressureAltitude(pressure: Double) -> Double {
        // Quick bounds check
        let stateMax = compute(altitude: ISAConstants.maxAltitude)
        if pressure <= stateMax.pressure { return ISAConstants.maxAltitude }
        if pressure >= ISAConstants.P0 { return 0 }

        var lo = 0.0
        var hi = ISAConstants.maxAltitude
        for _ in 0..<60 {
            let mid = (lo + hi) / 2
            let pMid = compute(altitude: mid).pressure
            if pMid > pressure {
                lo = mid
            } else {
                hi = mid
            }
            if hi - lo < 0.01 { break }
        }
        return (lo + hi) / 2
    }

    // MARK: - Density Altitude

    /// Compute density altitude given pressure altitude (m) and outside air temperature (K)
    static func densityAltitude(pressureAltitude pa: Double, oatKelvin oat: Double) -> Double {
        let state = compute(altitude: pa)
        let rhoActual = state.pressure / (ISAConstants.R * oat)
        return densityAltitudeFromDensity(rhoActual)
    }

    /// Given a density value, find the ISA altitude that produces that density.
    /// Uses bisection method with early convergence exit.
    static func densityAltitudeFromDensity(_ targetDensity: Double) -> Double {
        if targetDensity >= ISAConstants.rho0 { return 0 }

        var lo = 0.0
        var hi = ISAConstants.maxAltitude
        for _ in 0..<60 {
            let mid = (lo + hi) / 2
            let rhoMid = compute(altitude: mid).density
            if rhoMid > targetDensity {
                lo = mid
            } else {
                hi = mid
            }
            if hi - lo < 0.01 { break }
        }
        return (lo + hi) / 2
    }

    // MARK: - Profile Generation

    /// Generate atmosphere profile data for charting
    /// - Parameters:
    ///   - step: Altitude step in meters (default 250)
    ///   - isaDeviation: Temperature deviation from ISA
    /// - Returns: Array of atmosphere states from 0 to max altitude
    static func profile(step: Double = 250, isaDeviation: Double = 0) -> [AtmosphereState] {
        var results: [AtmosphereState] = []
        var h = 0.0
        while h <= ISAConstants.maxAltitude {
            results.append(compute(altitude: h, isaDeviation: isaDeviation))
            h += step
        }
        // Ensure the last point is exactly maxAltitude
        if results.last?.altitude != ISAConstants.maxAltitude {
            results.append(compute(altitude: ISAConstants.maxAltitude, isaDeviation: isaDeviation))
        }
        return results
    }
}

// MARK: - Helpers

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
