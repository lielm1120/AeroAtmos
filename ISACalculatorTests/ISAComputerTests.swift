import Foundation
import Testing
@testable import ISACalculator

/// Unit tests verified against ICAO Standard Atmosphere Table 1
/// Reference: ICAO Doc 7488/3 — Manual of the ICAO Standard Atmosphere
struct ISAComputerTests {

    // MARK: - Sea Level (h = 0 m)

    @Test func seaLevel() {
        let state = ISAComputer.compute(altitude: 0)
        #expect(abs(state.temperature - 288.15) < 0.01, "Sea level T")
        #expect(abs(state.pressure - 101_325) < 1, "Sea level P")
        #expect(abs(state.density - 1.225) < 0.001, "Sea level ρ")
        #expect(abs(state.speedOfSound - 340.29) < 0.1, "Sea level a")
    }

    // MARK: - Troposphere Test Points

    @Test func altitude1000m() {
        let state = ISAComputer.compute(altitude: 1_000)
        #expect(abs(state.temperature - 281.65) < 0.01, "T at 1 km")
        #expect(abs(state.pressure - 89_874.6) < 10, "P at 1 km")
        #expect(abs(state.density - 1.1117) < 0.001, "ρ at 1 km")
    }

    @Test func altitude5000m() {
        let state = ISAComputer.compute(altitude: 5_000)
        #expect(abs(state.temperature - 255.65) < 0.01, "T at 5 km")
        #expect(abs(state.pressure - 54_019.9) < 20, "P at 5 km")
        #expect(abs(state.density - 0.7361) < 0.001, "ρ at 5 km")
    }

    @Test func altitude10000m() {
        let state = ISAComputer.compute(altitude: 10_000)
        #expect(abs(state.temperature - 223.15) < 0.01, "T at 10 km")
        #expect(abs(state.pressure - 26_436.3) < 20, "P at 10 km")
        #expect(abs(state.density - 0.4127) < 0.001, "ρ at 10 km")
    }

    // MARK: - Tropopause Verification (10,972 m ≈ 36,000 ft)

    @Test func altitude10972m() {
        let state = ISAComputer.compute(altitude: 10_972)
        let expectedT = 288.15 - 0.0065 * 10_972
        #expect(abs(state.temperature - expectedT) < 0.1, "T at 10,972 m")
        let tRatio = expectedT / 288.15
        let expectedP = 101_325 * pow(tRatio, 5.2559)
        #expect(abs(state.pressure - expectedP) < 50, "P at 10,972 m")
    }

    // MARK: - Tropopause (h = 11,000 m)

    @Test func tropopause() {
        let state = ISAComputer.compute(altitude: 11_000)
        #expect(abs(state.temperature - 216.65) < 0.01, "T at 11 km")
        #expect(abs(state.pressure - 22_632.1) < 10, "P at 11 km")
        #expect(abs(state.density - 0.3639) < 0.001, "ρ at 11 km")
    }

    // MARK: - Stratosphere Test Points

    @Test func altitude15000m() {
        let state = ISAComputer.compute(altitude: 15_000)
        #expect(abs(state.temperature - 216.65) < 0.01, "T at 15 km")
        #expect(abs(state.pressure - 12_044.6) < 20, "P at 15 km")
    }

    @Test func altitude20000m() {
        let state = ISAComputer.compute(altitude: 20_000)
        #expect(abs(state.temperature - 216.65) < 0.01, "T at 20 km")
        #expect(abs(state.pressure - 5474.9) < 10, "P at 20 km")
        #expect(abs(state.density - 0.0880) < 0.001, "ρ at 20 km")
    }

    @Test func altitude32000m() {
        let state = ISAComputer.compute(altitude: 32_000)
        #expect(abs(state.temperature - 228.65) < 0.1, "T at 32 km")
        #expect(abs(state.pressure - 868.02) < 5, "P at 32 km")
    }

    // MARK: - Speed of Sound

    @Test func speedOfSoundSeaLevel() {
        let state = ISAComputer.compute(altitude: 0)
        let expected = sqrt(1.4 * 287.05287 * 288.15)
        #expect(abs(state.speedOfSound - expected) < 0.1)
    }

    @Test func speedOfSoundTropopause() {
        let state = ISAComputer.compute(altitude: 11_000)
        let expected = sqrt(1.4 * 287.05287 * 216.65)
        #expect(abs(state.speedOfSound - expected) < 0.1)
    }

    // MARK: - Viscosity

    @Test func dynamicViscositySeaLevel() {
        let state = ISAComputer.compute(altitude: 0)
        #expect(abs(state.dynamicViscosity - 1.789e-5) < 1e-7)
    }

    @Test func kinematicViscosityConsistency() {
        let state = ISAComputer.compute(altitude: 5_000)
        let expected = state.dynamicViscosity / state.density
        #expect(abs(state.kinematicViscosity - expected) < 1e-12)
    }

    // MARK: - ISA Deviation

    @Test func isaDeviationTemperature() {
        let standard = ISAComputer.compute(altitude: 5_000, isaDeviation: 0)
        let hot = ISAComputer.compute(altitude: 5_000, isaDeviation: 20)
        #expect(abs(hot.temperature - (standard.temperature + 20)) < 0.01)
    }

    @Test func isaDeviationPressureUnchanged() {
        let standard = ISAComputer.compute(altitude: 5_000, isaDeviation: 0)
        let hot = ISAComputer.compute(altitude: 5_000, isaDeviation: 20)
        #expect(abs(hot.pressure - standard.pressure) < 0.1)
    }

    @Test func isaDeviationDensityDecreases() {
        let standard = ISAComputer.compute(altitude: 5_000, isaDeviation: 0)
        let hot = ISAComputer.compute(altitude: 5_000, isaDeviation: 20)
        #expect(hot.density < standard.density, "Hotter temperature → lower density")
    }

    // MARK: - Altitude Conversions

    @Test func geometricToGeopotential() {
        let gp = ISAComputer.geometricToGeopotential(10_000)
        #expect(abs(gp - 9984.3) < 1.0, "Geopotential at 10 km geometric")
    }

    @Test func geopotentialToGeometric() {
        let gm = ISAComputer.geopotentialToGeometric(10_000)
        #expect(abs(gm - 10_015.8) < 1.0, "Geometric at 10 km geopotential")
    }

    @Test func altitudeConversionRoundTrip() {
        let original = 25_000.0
        let gp = ISAComputer.geometricToGeopotential(original)
        let back = ISAComputer.geopotentialToGeometric(gp)
        #expect(abs(back - original) < 0.01, "Round trip conversion")
    }

    // MARK: - Pressure Altitude (Back-Solve)

    @Test func pressureAltitudeSeaLevel() {
        let alt = ISAComputer.pressureAltitude(pressure: 101_325)
        #expect(abs(alt) < 1, "PA at sea level pressure")
    }

    @Test func pressureAltitudeFL350() {
        let state = ISAComputer.compute(altitude: 10_668)
        let alt = ISAComputer.pressureAltitude(pressure: state.pressure)
        #expect(abs(alt - 10_668) < 1, "PA round-trip at FL350")
    }

    // MARK: - Density Altitude

    @Test func densityAltitudeStandard() {
        let pa = 5_000.0
        let isaState = ISAComputer.compute(altitude: pa)
        let da = ISAComputer.densityAltitude(pressureAltitude: pa, oatKelvin: isaState.temperature)
        #expect(abs(da - pa) < 10, "DA = PA at standard conditions")
    }

    @Test func densityAltitudeHotDay() {
        let pa = 1_524.0
        let isaState = ISAComputer.compute(altitude: pa)
        let hotOAT = isaState.temperature + 20
        let da = ISAComputer.densityAltitude(pressureAltitude: pa, oatKelvin: hotOAT)
        #expect(da > pa, "Hot day → DA > PA")
    }

    @Test func densityAltitudeColdDay() {
        let pa = 1_524.0
        let isaState = ISAComputer.compute(altitude: pa)
        let coldOAT = isaState.temperature - 20
        let da = ISAComputer.densityAltitude(pressureAltitude: pa, oatKelvin: coldOAT)
        #expect(da < pa, "Cold day → DA < PA")
    }

    // MARK: - Boundary Conditions

    @Test func maxAltitude() {
        let state = ISAComputer.compute(altitude: 51_000)
        #expect(state.temperature > 0, "T > 0 at 51 km")
        #expect(state.pressure > 0, "P > 0 at 51 km")
        #expect(state.density > 0, "ρ > 0 at 51 km")
    }

    @Test func negativeAltitudeClamped() {
        let state = ISAComputer.compute(altitude: -1_000)
        let seaLevel = ISAComputer.compute(altitude: 0)
        #expect(abs(state.temperature - seaLevel.temperature) < 0.01)
    }

    @Test func excessiveAltitudeClamped() {
        let state = ISAComputer.compute(altitude: 100_000)
        let maxState = ISAComputer.compute(altitude: 51_000)
        #expect(abs(state.temperature - maxState.temperature) < 0.01)
    }

    // MARK: - Profile Generation

    @Test func profileGeneration() {
        let profile = ISAComputer.profile(step: 1000)
        #expect(profile.count > 50, "Profile should have > 50 points")
        #expect(profile.first?.altitude == 0, "Profile starts at 0")

        // Check monotonically decreasing pressure
        for i in 1..<profile.count {
            #expect(
                profile[i].pressure <= profile[i - 1].pressure,
                "Pressure must decrease with altitude"
            )
        }
    }

    // MARK: - Equation of State Consistency

    @Test func equationOfStateConsistency() {
        let altitudes: [Double] = [0, 3000, 7000, 11000, 15000, 20000, 30000, 45000]
        for h in altitudes {
            let state = ISAComputer.compute(altitude: h)
            let rhoCheck = state.pressure / (ISAConstants.R * state.temperature)
            #expect(
                abs(state.density - rhoCheck) < 1e-6,
                "Equation of state at \(h) m"
            )
        }
    }
}
