import SwiftUI

struct LiveBarometerView: View {
    @Environment(AtmosphereViewModel.self) private var viewModel
    @State private var isActive = false
    @State private var pulsePhase = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statusHero
                    if isActive {
                        if let error = viewModel.sensorError {
                            sensorErrorBanner(error)
                        }
                        pressureCard
                        altitudeCard
                        derivedCard
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.bottom, 16)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        if isActive {
                            Circle()
                                .fill(.green)
                                .frame(width: 7, height: 7)
                                .scaleEffect(pulsePhase ? 1.3 : 1.0)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulsePhase)
                        }
                        Text(String(localized: "Live Barometer"))
                            .font(.headline)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                pulsePhase = true
            }
            .onDisappear {
                if isActive {
                    viewModel.stopLiveSensors()
                    isActive = false
                }
            }
        }
    }

    // MARK: - Status Hero

    private var statusHero: some View {
        VStack(spacing: 16) {
            // Sensor icon
            ZStack {
                Circle()
                    .fill(isActive ? Color.green.opacity(0.1) : Color(.tertiarySystemFill))
                    .frame(width: 80, height: 80)

                if isActive {
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulsePhase ? 1.3 : 1.0)
                        .opacity(pulsePhase ? 0.0 : 0.8)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulsePhase)
                }

                Image(systemName: isActive ? "waveform.circle.fill" : "waveform.circle")
                    .font(.system(size: 36))
                    .foregroundStyle(isActive ? .green : .secondary)
                    .symbolEffect(.pulse, isActive: isActive)
            }

            VStack(spacing: 4) {
                Text(isActive ? String(localized: "Sensors Active") : String(localized: "Sensors Inactive"))
                    .font(.headline)
                Text(AltimeterService.isAvailable
                     ? String(localized: "Barometer available")
                     : String(localized: "Barometer not available (simulator?)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                withAnimation(.snappy) {
                    if isActive {
                        viewModel.stopLiveSensors()
                        isActive = false
                    } else {
                        viewModel.startLiveSensors()
                        isActive = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                    Text(isActive ? String(localized: "Stop Sensors") : String(localized: "Start Sensors"))
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(isActive ? .red : AppColors.pressure)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel(isActive ? String(localized: "Stop Sensors") : String(localized: "Start Sensors"))
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Pressure Card

    private var pressureCard: some View {
        VStack(spacing: 12) {
            SectionHeader(title: String(localized: "Barometer"), icon: "barometer", color: AppColors.pressure)

            if let pressure = viewModel.livePressureHPa {
                // Big pressure display
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.2f", pressure))
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText(value: pressure))
                        .animation(.snappy, value: pressure)
                    Text(String(localized: "hPa"))
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }

                Divider()

                sensorRow(
                    icon: "gauge.with.dots.needle.bottom.50percent",
                    label: String(localized: "Pressure (inHg)"),
                    value: String(format: "%.4f", pressure * 0.02953),
                    color: AppColors.pressure
                )
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(String(localized: "Waiting for Data"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 16)
            }
        }
        .padding(14)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
    }

    // MARK: - Altitude Card

    private var altitudeCard: some View {
        VStack(spacing: 12) {
            SectionHeader(title: String(localized: "Altitude"), icon: "mountain.2.fill", color: AppColors.density)

            if let pa = viewModel.livePressureAltitude {
                sensorRow(
                    icon: "barometer",
                    label: String(localized: "Pressure Altitude"),
                    value: String(format: "%.0f m  (%.0f ft)", pa, pa * ISAConstants.feetPerMeter),
                    color: AppColors.pressure
                )

                let state = ISAComputer.compute(altitude: pa)
                sensorRow(
                    icon: "thermometer.medium",
                    label: String(localized: "ISA Temperature"),
                    value: String(format: "%.1f °C", state.temperatureC),
                    color: AppColors.temperature
                )

                if let gpsAlt = viewModel.gpsAltitude {
                    Divider()

                    sensorRow(
                        icon: "location.fill",
                        label: String(localized: "GPS Altitude (MSL)"),
                        value: String(format: "%.1f m  (%.0f ft)", gpsAlt, gpsAlt * ISAConstants.feetPerMeter),
                        color: .green
                    )

                    let gpsDiff = gpsAlt - pa
                    sensorRow(
                        icon: "arrow.up.arrow.down",
                        label: String(localized: "GPS − Pressure Alt"),
                        value: String(format: "%+.1f m", gpsDiff),
                        color: abs(gpsDiff) > 50 ? .orange : .green
                    )
                }
            } else if let gpsAlt = viewModel.gpsAltitude {
                sensorRow(
                    icon: "location.fill",
                    label: String(localized: "GPS Altitude (MSL)"),
                    value: String(format: "%.1f m", gpsAlt),
                    color: .green
                )
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(String(localized: "Waiting for altitude data"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(14)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
    }

    // MARK: - Derived Card

    private var derivedCard: some View {
        VStack(spacing: 12) {
            SectionHeader(title: String(localized: "Derived Atmosphere"), icon: "function", color: AppColors.speedSound)

            if let pa = viewModel.livePressureAltitude {
                let state = ISAComputer.compute(altitude: pa)

                sensorRow(
                    icon: "speaker.wave.3",
                    label: String(localized: "Speed of Sound (est.)"),
                    value: String(format: "%.1f m/s  (%.1f kts)", state.speedOfSound, state.speedOfSoundKnots),
                    color: AppColors.speedSound
                )
                sensorRow(
                    icon: "aqi.medium",
                    label: String(localized: "Air Density (est.)"),
                    value: String(format: "%.6f kg/m³", state.density),
                    color: AppColors.density
                )
                sensorRow(
                    icon: "percent",
                    label: String(localized: "Density Ratio"),
                    value: String(format: "σ = %.4f", state.densityRatio),
                    color: AppColors.density
                )

                Divider()

                Text(String(localized: "Note: Temperature and density estimated from ISA using measured pressure. Actual values depend on local weather."))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text(String(localized: "Derived values require barometric data"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding(14)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sensor.tag.radiowaves.forward")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: 4) {
                Text(String(localized: "Tap Start to begin reading live atmospheric data"))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                Text(String(localized: "Uses your iPhone's built-in barometric sensor and GPS"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let error = viewModel.sensorError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundStyle(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.red.opacity(0.1), in: Capsule())
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error Banner

    private func sensorErrorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline)
            Text(message)
                .font(.caption)
        }
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Sensor Row

    private func sensorRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Text(value)
                .font(.caption.monospacedDigit().bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

#Preview {
    LiveBarometerView()
        .environment(AtmosphereViewModel())
}
