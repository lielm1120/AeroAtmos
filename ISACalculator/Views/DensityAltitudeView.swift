import SwiftUI

struct DensityAltitudeView: View {
    @Environment(AtmosphereViewModel.self) private var viewModel
    @State private var showMath = false

    private var daFt: Double { viewModel.densityAltitudeResult * ISAConstants.feetPerMeter }
    private var paFt: Double { viewModel.densityPressureAltitudeFt }
    private var diff: Double { daFt - paFt }
    private var isaTemp: Double { viewModel.densityAltitudeISATemp }
    private var tempDiff: Double { viewModel.densityOATCelsius - isaTemp }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    resultHero
                    comparisonBar
                    inputsCard
                    mathCard
                    infoCard
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.bottom, 16)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "Density Altitude"))
                        .font(.headline)
                }
            }
            .background(Color(.systemGroupedBackground))
            .onAppear { viewModel.computeDensityAltitude() }
        }
    }

    // MARK: - Result Hero

    private var resultHero: some View {
        VStack(spacing: 16) {
            // Ring gauge
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(.tertiarySystemFill), lineWidth: 10)
                    .frame(width: 180, height: 180)

                // Colored progress ring
                Circle()
                    .trim(from: 0, to: min(max(daFt / 50_000, 0), 1))
                    .stroke(
                        AngularGradient(
                            colors: [performanceColor.opacity(0.6), performanceColor],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.snappy(duration: 0.5), value: daFt)

                // Center label
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", daFt))
                        .font(.system(size: 38, weight: .bold, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText(value: daFt))
                        .animation(.snappy(duration: 0.3), value: daFt)
                    Text(String(localized: "ft"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f m", viewModel.densityAltitudeResult))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }

            // Performance badge
            HStack(spacing: 6) {
                Image(systemName: performanceIcon)
                    .font(.caption.bold())
                Text(performanceLabel)
                    .font(.caption.bold())
            }
            .foregroundStyle(performanceColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(performanceColor.opacity(0.12), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: "Density altitude: %.0f feet. %@", daFt, performanceLabel))
    }

    // MARK: - Comparison Bar

    private var comparisonBar: some View {
        VStack(spacing: 10) {
            // PA vs DA comparison
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(String(localized: "PA"))
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f ft", paFt))
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(AppColors.pressure)
                }
                .frame(maxWidth: .infinity)

                // Arrow with diff
                VStack(spacing: 2) {
                    Image(systemName: diff > 0 ? "arrow.right" : "arrow.left")
                        .font(.caption.bold())
                    Text(String(format: "%+.0f ft", diff))
                        .font(.caption.monospacedDigit().bold())
                }
                .foregroundStyle(diff > 0 ? Color.red : Color.blue)

                VStack(spacing: 2) {
                    Text(String(localized: "DA"))
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f ft", daFt))
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(performanceColor)
                }
                .frame(maxWidth: .infinity)
            }

            // Visual bar
            GeometryReader { geo in
                let maxVal = max(daFt, paFt, 1)
                let paWidth = (paFt / maxVal) * geo.size.width
                let daWidth = (daFt / maxVal) * geo.size.width

                ZStack(alignment: .leading) {
                    // PA bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.pressure.opacity(0.3))
                        .frame(width: max(paWidth, 4), height: 8)

                    // DA bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(performanceColor.gradient)
                        .frame(width: max(daWidth, 4), height: 8)
                        .offset(y: 12)
                }
                .animation(.snappy(duration: 0.4), value: daFt)
                .animation(.snappy(duration: 0.4), value: paFt)
            }
            .frame(height: 24)
        }
        .padding(14)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - Inputs

    private var inputsCard: some View {
        VStack(spacing: 16) {
            SectionHeader(title: String(localized: "Conditions"), icon: "cloud.sun", color: AppColors.pressure)

            // Pressure Altitude slider
            VStack(spacing: 6) {
                HStack {
                    Text(String(localized: "Pressure Altitude"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f ft", viewModel.densityPressureAltitudeFt))
                        .font(.subheadline.monospacedDigit().bold())
                        .contentTransition(.numericText(value: viewModel.densityPressureAltitudeFt))
                        .animation(.snappy, value: viewModel.densityPressureAltitudeFt)
                }
                Slider(value: Bindable(viewModel).densityPressureAltitudeFt, in: 0...50_000, step: 100)
                    .tint(AppColors.pressure)
                    .onChange(of: viewModel.densityPressureAltitudeFt) { viewModel.computeDensityAltitude() }
            }

            Divider()

            // OAT slider
            VStack(spacing: 6) {
                HStack {
                    Text(String(localized: "Outside Air Temp (OAT)"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f °C", viewModel.densityOATCelsius))
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(tempDiff > 0 ? AppColors.temperature : AppColors.pressure)
                        .contentTransition(.numericText(value: viewModel.densityOATCelsius))
                        .animation(.snappy, value: viewModel.densityOATCelsius)
                }
                Slider(value: Bindable(viewModel).densityOATCelsius, in: -60...60, step: 0.5)
                    .tint(tempDiff > 0 ? AppColors.temperature : AppColors.pressure)
                    .onChange(of: viewModel.densityOATCelsius) { viewModel.computeDensityAltitude() }

                // ISA comparison
                HStack(spacing: 4) {
                    Image(systemName: "thermometer.variable")
                        .font(.caption2)
                    Text(String(format: "ISA: %.1f °C", isaTemp))
                        .font(.caption2)
                    Text(String(format: "(ΔT %+.1f °C)", tempDiff))
                        .font(.caption2.bold())
                        .foregroundStyle(abs(tempDiff) < 1 ? Color.green : AppColors.temperature)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - Math Card

    private var mathCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy) { showMath.toggle() }
            } label: {
                HStack {
                    IconBadge(systemName: "function", color: AppColors.pressure, size: 24)
                    Text(String(localized: "Show the Math"))
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showMath ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if showMath {
                let paMeters = viewModel.densityPressureAltitudeFt * ISAConstants.meterPerFoot
                let oatK = viewModel.densityOATCelsius + 273.15
                let pAtPA = ISAComputer.compute(altitude: paMeters).pressure
                let rho = pAtPA / (ISAConstants.R * oatK)

                VStack(alignment: .leading, spacing: 6) {
                    mathStep("1", "Pressure at PA (\(String(format: "%.0f", paMeters)) m)")
                    mathLine("P = \(String(format: "%.2f", pAtPA)) Pa")

                    mathStep("2", "Actual density")
                    mathLine("ρ = P / (R·T) = \(String(format: "%.6f", rho)) kg/m³")

                    mathStep("3", "Back-solve ISA")
                    mathLine("DA = \(String(format: "%.0f", viewModel.densityAltitudeResult)) m = \(String(format: "%.0f", daFt)) ft")
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private func mathStep(_ num: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Text(num)
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(AppColors.pressure.gradient, in: Circle())
            Text(text)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }

    private func mathLine(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.leading, 26)
    }

    // MARK: - Info

    private var infoCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundStyle(AppColors.pressure.opacity(0.5))

            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "Higher density altitude = thinner air = reduced aircraft performance."))
                    .font(.caption.bold())
                Text(String(localized: "Hot days and high elevations both increase density altitude."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(AppColors.pressure.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Performance Thresholds

    private static let highDAThreshold: Double = 3000
    private static let elevatedDAThreshold: Double = 1500
    private static let moderateDAThreshold: Double = 500

    private var performanceColor: Color {
        if diff > Self.highDAThreshold { return .red }
        if diff > Self.elevatedDAThreshold { return .orange }
        if diff > Self.moderateDAThreshold { return .yellow }
        return .green
    }

    private var performanceLabel: String {
        if diff > Self.highDAThreshold { return String(localized: "High DA — Caution") }
        if diff > Self.elevatedDAThreshold { return String(localized: "Elevated DA") }
        if diff > Self.moderateDAThreshold { return String(localized: "Moderate DA") }
        return String(localized: "Standard")
    }

    private var performanceIcon: String {
        if diff > Self.highDAThreshold { return "exclamationmark.triangle.fill" }
        if diff > Self.elevatedDAThreshold { return "exclamationmark.circle.fill" }
        if diff > Self.moderateDAThreshold { return "info.circle.fill" }
        return "checkmark.circle.fill"
    }
}

#Preview {
    DensityAltitudeView()
        .environment(AtmosphereViewModel())
}
