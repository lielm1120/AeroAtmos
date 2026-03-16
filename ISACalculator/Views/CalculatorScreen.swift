import SwiftUI

struct CalculatorScreen: View {
    @Environment(AtmosphereViewModel.self) private var viewModel
    @State private var showShareSheet = false

    private var exportText: String {
        let s = viewModel.currentState
        let h = viewModel.geopotentialAltitudeMeters()
        let layer = LayerInfo.forAltitude(h)
        return """
        AeroAtmos — ISA Atmosphere Report
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Altitude:    \(viewModel.formattedAltitude) (\(layer.name))
        ISA Dev:     \(String(format: "%+.1f °C", viewModel.isaDeviation))

        Temperature: \(String(format: "%.2f K  (%.2f °C / %.1f °F)", s.temperature, s.temperatureC, s.temperatureF))
        Pressure:    \(String(format: "%.2f Pa  (%.4f hPa / %.4f inHg)", s.pressure, s.pressureHPa, s.pressureInHg))
        Density:     \(String(format: "%.6f kg/m³", s.density))
        Speed/Sound: \(String(format: "%.2f m/s  (%.1f kts)", s.speedOfSound, s.speedOfSoundKnots))
        Dyn. Visc:   \(String(format: "%.4e Pa·s", s.dynamicViscosity))
        Kin. Visc:   \(String(format: "%.4e m²/s", s.kinematicViscosity))

        Ratios: T/T₀=\(String(format: "%.6f", s.temperatureRatio))  P/P₀=\(String(format: "%.6f", s.pressureRatio))  ρ/ρ₀=\(String(format: "%.6f", s.densityRatio))
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        ICAO Standard Atmosphere (Doc 7488/3)
        """
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    inputSection
                        .padding(.top, -20)
                        .zIndex(1)
                    resultsGrid
                        .padding(.top, 12)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            .contentMargins(.bottom, 16)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "Done")) {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "ISA Calculator"))
                        .font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [exportText])
                    .presentationDetents([.medium])
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Hero Header

    private var heroSection: some View {
        let layer = LayerInfo.forAltitude(viewModel.geopotentialAltitudeMeters())

        return ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    layer.color.opacity(0.8),
                    layer.color.opacity(0.4),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)

            VStack(spacing: 8) {
                // Layer badge
                HStack(spacing: 6) {
                    Image(systemName: layer.icon)
                        .font(.caption.bold())
                    Text(layer.name.uppercased())
                        .font(.caption.bold())
                        .tracking(1.5)
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(.white.opacity(0.2), in: Capsule())

                // Large altitude display
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.0f", viewModel.altitudeInput))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: viewModel.altitudeInput))
                        .animation(.snappy(duration: 0.3), value: viewModel.altitudeInput)
                    Text(viewModel.altitudeUnit.rawValue)
                        .font(.title3.bold())
                        .foregroundStyle(.white.opacity(0.7))
                }
                .foregroundStyle(.white)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(format: "%.0f %@", viewModel.altitudeInput, viewModel.altitudeUnit.label))

                // Layer position bar
                AtmosphereLayerBar(altitudeMeters: viewModel.geopotentialAltitudeMeters())
                    .frame(width: 200)

                // Layer range
                Text(layer.altitudeRange)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Input Card

    private var inputSection: some View {
        VStack(spacing: 14) {
            // Altitude slider
            VStack(spacing: 8) {
                Slider(
                    value: Bindable(viewModel).altitudeInput,
                    in: 0...viewModel.altitudeUnit.maxSlider,
                    step: viewModel.altitudeUnit == .meters ? 100 : 500
                ) {
                    Text(String(localized: "Altitude"))
                } onEditingChanged: { _ in
                    viewModel.altitudeText = String(format: "%.0f", viewModel.altitudeInput)
                }
                .tint(LayerInfo.forAltitude(viewModel.geopotentialAltitudeMeters()).color)

                HStack {
                    Text("0")
                    Spacer()
                    // Manual entry
                    HStack(spacing: 4) {
                        TextField("0", text: Bindable(viewModel).altitudeText)
                            .keyboardType(.decimalPad)
                            .font(.subheadline.monospacedDigit().bold())
                            .multilineTextAlignment(.center)
                            .frame(width: 80)
                            .padding(.vertical, 6)
                            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                        Text(viewModel.altitudeUnit.rawValue)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.0f", viewModel.altitudeUnit.maxSlider))
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }

            // Toggle row
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Unit"))
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Picker("Unit", selection: Bindable(viewModel).altitudeUnit) {
                        ForEach(AltitudeUnit.allCases) { u in Text(u.label).tag(u) }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Type"))
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Picker("Type", selection: Bindable(viewModel).altitudeType) {
                        ForEach(AltitudeType.allCases) { t in Text(t.label).tag(t) }
                    }
                    .pickerStyle(.segmented)
                }
            }

            // ISA Deviation
            VStack(spacing: 6) {
                HStack {
                    Text(String(localized: "ISA Deviation (ΔT)"))
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text(String(format: "%+.1f °C", viewModel.isaDeviation))
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(viewModel.isaDeviation == 0 ? Color.secondary : AppColors.temperature)
                        .contentTransition(.numericText(value: viewModel.isaDeviation))
                        .animation(.snappy, value: viewModel.isaDeviation)
                }
                Slider(value: Bindable(viewModel).isaDeviation, in: -50...50, step: 0.5)
                    .tint(viewModel.isaDeviation == 0 ? Color.secondary : AppColors.temperature)
            }
        }
        .glassCard()
        .padding(.horizontal, 16)
    }

    // MARK: - Results Grid

    private var resultsGrid: some View {
        VStack(spacing: 10) {
            // Row 1: Temperature & Pressure
            HStack(spacing: 10) {
                PropertyCard(
                    icon: "thermometer.medium",
                    title: String(localized: "Temperature"),
                    accent: AppColors.temperature,
                    primaryText: String(format: "%.2f", viewModel.currentState.temperatureC),
                    primaryUnit: "°C",
                    rows: [
                        (String(format: "%.2f K", viewModel.currentState.temperature), nil),
                        (String(format: "%.1f °F", viewModel.currentState.temperatureF), nil),
                        ("T/T₀", String(format: "%.4f", viewModel.currentState.temperatureRatio)),
                    ],
                    mathDetail: temperatureMath
                )
                PropertyCard(
                    icon: "gauge.with.dots.needle.33percent",
                    title: String(localized: "Pressure"),
                    accent: AppColors.pressure,
                    primaryText: String(format: "%.2f", viewModel.currentState.pressureHPa),
                    primaryUnit: "hPa",
                    rows: [
                        (String(format: "%.2f Pa", viewModel.currentState.pressure), nil),
                        (String(format: "%.3f inHg", viewModel.currentState.pressureInHg), nil),
                        ("P/P₀", String(format: "%.4f", viewModel.currentState.pressureRatio)),
                    ],
                    mathDetail: pressureMath
                )
            }

            // Row 2: Density & Speed of Sound
            HStack(spacing: 10) {
                PropertyCard(
                    icon: "aqi.medium",
                    title: String(localized: "Density"),
                    accent: AppColors.density,
                    primaryText: String(format: "%.4f", viewModel.currentState.density),
                    primaryUnit: "kg/m³",
                    rows: [
                        ("ρ/ρ₀", String(format: "%.4f", viewModel.currentState.densityRatio)),
                    ],
                    mathDetail: densityMath
                )
                PropertyCard(
                    icon: "speaker.wave.3",
                    title: String(localized: "Speed of Sound"),
                    accent: AppColors.speedSound,
                    primaryText: String(format: "%.1f", viewModel.currentState.speedOfSound),
                    primaryUnit: "m/s",
                    rows: [
                        (String(format: "%.1f kts", viewModel.currentState.speedOfSoundKnots), nil),
                        ("Mach 1", String(format: "%.1f m/s", viewModel.currentState.speedOfSound)),
                    ],
                    mathDetail: speedOfSoundMath
                )
            }

            // Row 3: Viscosities (full width)
            HStack(spacing: 10) {
                PropertyCard(
                    icon: "drop.fill",
                    title: "μ " + String(localized: "Dynamic"),
                    accent: AppColors.viscosity,
                    primaryText: String(format: "%.3e", viewModel.currentState.dynamicViscosity),
                    primaryUnit: "Pa·s",
                    rows: [],
                    mathDetail: viscosityMath
                )
                PropertyCard(
                    icon: "drop.triangle.fill",
                    title: "ν " + String(localized: "Kinematic"),
                    accent: AppColors.kinematic,
                    primaryText: String(format: "%.3e", viewModel.currentState.kinematicViscosity),
                    primaryUnit: "m²/s",
                    rows: [],
                    mathDetail: kinematicMath
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Math Detail Strings

    private var temperatureMath: String {
        let h = viewModel.geopotentialAltitudeMeters()
        if h <= 11_000 {
            return "Troposphere (0–11 km):\nT = T₀ − λh\nT = 288.15 − 0.0065 × \(String(format: "%.1f", h))\nT = \(String(format: "%.2f", viewModel.currentState.temperature)) K"
        } else if h <= 20_000 {
            return "Tropopause (11–20 km):\nT = 216.65 K (isothermal)"
        } else {
            return "h = \(String(format: "%.0f", h)) m\nT = \(String(format: "%.2f", viewModel.currentState.temperature)) K"
        }
    }

    private var pressureMath: String {
        let h = viewModel.geopotentialAltitudeMeters()
        if h <= 11_000 {
            return "P = P₀ × (T/T₀)^5.2559\nP = 101325 × (\(String(format: "%.2f", viewModel.currentState.temperature))/288.15)^5.2559\nP = \(String(format: "%.2f", viewModel.currentState.pressure)) Pa"
        } else if h <= 20_000 {
            return "Isothermal:\nP = P₁₁ × exp(−g₀·Δh / (R·T))\nP = \(String(format: "%.2f", viewModel.currentState.pressure)) Pa"
        } else {
            return "P = \(String(format: "%.2f", viewModel.currentState.pressure)) Pa"
        }
    }

    private var densityMath: String {
        "ρ = P / (R·T)\nρ = \(String(format: "%.2f", viewModel.currentState.pressure)) / (287.05 × \(String(format: "%.2f", viewModel.currentState.temperature)))\nρ = \(String(format: "%.6f", viewModel.currentState.density)) kg/m³"
    }

    private var speedOfSoundMath: String {
        "a = √(γ·R·T)\na = √(1.4 × 287.05 × \(String(format: "%.2f", viewModel.currentState.temperature)))\na = \(String(format: "%.2f", viewModel.currentState.speedOfSound)) m/s"
    }

    private var viscosityMath: String {
        "Sutherland's Law:\nμ = C₁·T^1.5 / (T + S)\nμ = \(String(format: "%.4e", viewModel.currentState.dynamicViscosity)) Pa·s"
    }

    private var kinematicMath: String {
        "ν = μ / ρ\nν = \(String(format: "%.4e", viewModel.currentState.dynamicViscosity)) / \(String(format: "%.6f", viewModel.currentState.density))\nν = \(String(format: "%.4e", viewModel.currentState.kinematicViscosity)) m²/s"
    }
}

// MARK: - Property Card

struct PropertyCard: View {
    let icon: String
    let title: String
    let accent: Color
    let primaryText: String
    let primaryUnit: String
    let rows: [(String, String?)]  // (label/value, optional right-side value)
    let mathDetail: String?

    @State private var showMath = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                IconBadge(systemName: icon, color: accent, size: 28)
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Primary value
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(primaryText)
                    .font(.title3.monospacedDigit().bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(primaryUnit)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title): \(primaryText) \(primaryUnit)")

            // Detail rows
            if !rows.isEmpty {
                VStack(spacing: 3) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        if let rightValue = row.1 {
                            HStack {
                                Text(row.0)
                                    .foregroundStyle(.tertiary)
                                Spacer()
                                Text(rightValue)
                                    .monospacedDigit()
                            }
                            .font(.caption2)
                        } else {
                            HStack {
                                Text(row.0)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .font(.caption2)
                        }
                    }
                }
            }

            // Show the Math
            if let mathDetail {
                Button {
                    withAnimation(.snappy) { showMath.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showMath ? "chevron.up" : "function")
                            .font(.caption2)
                        Text(String(localized: "Math"))
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(accent)
                }

                if showMath {
                    Text(mathDetail)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    CalculatorScreen()
        .environment(AtmosphereViewModel())
}
