import SwiftUI
import Charts

struct AtmosphereChartView: View {
    @Environment(AtmosphereViewModel.self) private var viewModel
    @State private var selectedProperty: AtmosphereProperty = .temperature
    @State private var dragAltitude: Double? = nil


    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                propertySelector
                chartSection
                legendBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "Atmosphere Profile"))
                        .font(.headline)
                }
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                if viewModel.profileData.isEmpty {
                    viewModel.generateProfile()
                }
            }
        }
    }

    // MARK: - Property Selector

    private var propertySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AtmosphereProperty.allCases) { prop in
                    let isSelected = selectedProperty == prop
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            selectedProperty = prop
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorFor(prop).gradient)
                                .frame(width: 8, height: 8)
                            Text(prop.label)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            isSelected
                                ? colorFor(prop).opacity(0.15)
                                : Color(.tertiarySystemFill)
                        )
                        .foregroundStyle(isSelected ? colorFor(prop) : .secondary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(isSelected ? colorFor(prop).opacity(0.4) : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.bar)
    }

    // MARK: - Chart

    private var chartSection: some View {
        let color = colorFor(selectedProperty)
        let data = viewModel.profileData
        let currentAlt = viewModel.geopotentialAltitudeMeters() / 1000

        return Chart {
            // Layer background bands
            layerBands

            // Main data line
            ForEach(data) { state in
                LineMark(
                    x: .value(selectedProperty.label, selectedProperty.value(from: state)),
                    y: .value("Altitude", state.altitude / 1000)
                )
                .foregroundStyle(color.gradient)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.monotone)
            }

            // Area fill
            ForEach(data) { state in
                AreaMark(
                    x: .value(selectedProperty.label, selectedProperty.value(from: state)),
                    y: .value("Altitude", state.altitude / 1000)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.2), color.opacity(0.02)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .interpolationMethod(.monotone)
            }

            // Current altitude marker
            RuleMark(y: .value("Current", currentAlt))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                .foregroundStyle(.primary.opacity(0.4))

            // Current altitude point
            let currentValue = selectedProperty.value(from: viewModel.currentState)
            PointMark(
                x: .value("Value", currentValue),
                y: .value("Alt", currentAlt)
            )
            .symbolSize(50)
            .foregroundStyle(color)
            .annotation(position: .topLeading, spacing: 6) {
                tooltipView(value: currentValue, altitude: currentAlt)
            }

            // Drag indicator
            if let dragAlt = dragAltitude {
                RuleMark(y: .value("Drag", dragAlt / 1000))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .foregroundStyle(color.opacity(0.6))
            }
        }
        .chartYScale(domain: 0...51)
        .chartXAxisLabel(selectedProperty.unit)
        .chartYAxisLabel("km")
        .chartXAxis {
            AxisMarks(position: .bottom) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50]) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plotFrame = proxy.plotFrame else { return }
                                let origin = geo[plotFrame].origin
                                let locationY = value.location.y - origin.y
                                if let altKm: Double = proxy.value(atY: locationY) {
                                    let altM = max(0, min(51_000, altKm * 1000))
                                    withAnimation(.interactiveSpring) {
                                        dragAltitude = altM
                                    }
                                    viewModel.setAltitudeFromChart(altM)
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.snappy) { dragAltitude = nil }
                            }
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxHeight: .infinity)
    }

    // Layer background bands
    @ChartContentBuilder
    private var layerBands: some ChartContent {
        RectangleMark(yStart: .value("", 0), yEnd: .value("", 11))
            .foregroundStyle(AppColors.troposphere.opacity(0.06))
        RectangleMark(yStart: .value("", 11), yEnd: .value("", 20))
            .foregroundStyle(AppColors.tropopause.opacity(0.06))
        RectangleMark(yStart: .value("", 20), yEnd: .value("", 32))
            .foregroundStyle(AppColors.stratosphere.opacity(0.06))
        RectangleMark(yStart: .value("", 32), yEnd: .value("", 47))
            .foregroundStyle(AppColors.stratopause.opacity(0.06))
        RectangleMark(yStart: .value("", 47), yEnd: .value("", 51))
            .foregroundStyle(AppColors.mesosphere.opacity(0.06))
    }

    // Tooltip
    private func tooltipView(value: Double, altitude: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(format: "%.1f km", altitude))
                .font(.caption2.bold())
            Text(String(format: "%.\(selectedProperty == .pressure || selectedProperty == .density ? "4" : "1")f %@", value, selectedProperty.unit))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    // MARK: - Legend

    private var legendBar: some View {
        VStack(spacing: 8) {
            Divider()
            HStack(spacing: 0) {
                layerLegendItem("Tropo", color: AppColors.troposphere, range: "0–11")
                layerLegendItem("Pause", color: AppColors.tropopause, range: "11–20")
                layerLegendItem("Strato", color: AppColors.stratosphere, range: "20–47")
                layerLegendItem("Meso", color: AppColors.mesosphere, range: "47–51")
            }
            .padding(.horizontal)

            if viewModel.isaDeviation != 0 {
                HStack(spacing: 4) {
                    Image(systemName: "thermometer.variable")
                        .font(.caption2)
                    Text(String(format: "ISA %+.1f °C", viewModel.isaDeviation))
                        .font(.caption2.bold())
                }
                .foregroundStyle(AppColors.temperature)
                .padding(.bottom, 4)
            }
        }
        .padding(.bottom, 6)
    }

    private func layerLegendItem(_ name: String, color: Color, range: String) -> some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.gradient)
                .frame(height: 3)
            Text(name)
                .font(.system(size: 9, weight: .bold))
            Text("\(range) km")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Colors

    private func colorFor(_ prop: AtmosphereProperty) -> Color {
        switch prop {
        case .temperature: return AppColors.temperature
        case .pressure:    return AppColors.pressure
        case .density:     return AppColors.density
        case .speedOfSound: return AppColors.speedSound
        }
    }
}

#Preview {
    AtmosphereChartView()
        .environment(AtmosphereViewModel())
}
