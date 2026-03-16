import SwiftUI

struct ReferenceTableView: View {
    @State private var selectedUnit: AltitudeUnit = .meters
    @State private var searchText = ""
    @State private var highlightedAlt: Double? = nil

    // Pre-computed table data at 1 km intervals
    private let tableData: [AtmosphereState] = {
        var data: [AtmosphereState] = []
        var h = 0.0
        while h <= 51_000 {
            data.append(ISAComputer.compute(altitude: h))
            h += 1_000
        }
        return data
    }()

    // Common flight levels for highlighting (in meters)
    private let flightLevels: Set<Double> = [
        0, 3_048, 6_096, 9_144, 10_668, 10_972, 11_000, 12_192, 15_240, 18_288
    ] // FL0, FL100, FL200, FL300, FL350, FL360, ~11km, FL400, FL500, FL600

    private var filteredData: [AtmosphereState] {
        if searchText.isEmpty { return tableData }
        guard let val = Double(searchText) else { return tableData }
        let searchAlt = selectedUnit == .feet ? val * ISAConstants.meterPerFoot : val
        // Show rows within 3km of search value
        return tableData.filter { abs($0.altitude - searchAlt) <= 3_000 }
    }

    var body: some View {
        VStack(spacing: 0) {
            unitAndSearchBar
            tableHeader
            tableContent
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Search & Unit Bar

    private var unitAndSearchBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Search
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField(String(localized: "Search altitude..."), text: $searchText)
                        .keyboardType(.decimalPad)
                        .font(.subheadline)
                }
                .padding(8)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))

                // Unit picker
                Picker("Unit", selection: $selectedUnit) {
                    ForEach(AltitudeUnit.allCases) { u in Text(u.label).tag(u) }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Table Header

    private var tableHeader: some View {
        HStack(spacing: 0) {
            headerCell("h", unit: selectedUnit == .meters ? "m" : "ft", width: .altitude)
            headerCell("T", unit: "K", width: .temperature)
            headerCell("P", unit: "Pa", width: .pressure)
            headerCell("ρ", unit: "kg/m³", width: .density)
            headerCell("a", unit: "m/s", width: .speed)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemFill))
    }

    private func headerCell(_ symbol: String, unit: String, width: ColumnWidth) -> some View {
        VStack(spacing: 1) {
            Text(symbol)
                .font(.subheadline.bold())
            Text(unit)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(width: width.value, alignment: .trailing)
    }

    // MARK: - Table Content

    private var tableContent: some View {
        ScrollViewReader { scrollProxy in
            List(filteredData) { state in
                let isFlightLevel = isNearFlightLevel(state.altitude)
                let isHighlighted = highlightedAlt == state.altitude

                tableRow(state, highlight: isFlightLevel, selected: isHighlighted)
                    .id(state.altitude)
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    .listRowBackground(
                        isHighlighted ? AppColors.pressure.opacity(0.1) :
                        isFlightLevel ? AppColors.troposphere.opacity(0.06) : Color.clear
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.snappy) {
                            highlightedAlt = highlightedAlt == state.altitude ? nil : state.altitude
                        }
                    }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func tableRow(_ state: AtmosphereState, highlight: Bool, selected: Bool) -> some View {
        HStack(spacing: 0) {
            // Altitude
            Text(altitudeString(state.altitude))
                .frame(width: ColumnWidth.altitude.value, alignment: .trailing)
                .foregroundStyle(highlight ? AppColors.pressure : .primary)
                .fontWeight(highlight ? .semibold : .regular)

            // Temperature
            Text(String(format: "%.2f", state.temperature))
                .frame(width: ColumnWidth.temperature.value, alignment: .trailing)
                .foregroundStyle(AppColors.temperature)

            // Pressure
            Text(pressureString(state.pressure))
                .frame(width: ColumnWidth.pressure.value, alignment: .trailing)
                .foregroundStyle(AppColors.pressure)

            // Density
            Text(densityString(state.density))
                .frame(width: ColumnWidth.density.value, alignment: .trailing)
                .foregroundStyle(AppColors.density)

            // Speed of sound
            Text(String(format: "%.1f", state.speedOfSound))
                .frame(width: ColumnWidth.speed.value, alignment: .trailing)
                .foregroundStyle(AppColors.speedSound)
        }
        .font(.system(size: 12, design: .monospaced))

    }

    // MARK: - Detail Row (shown on tap)

    // MARK: - Helpers

    private func altitudeString(_ altM: Double) -> String {
        if selectedUnit == .feet {
            return String(format: "%.0f", altM * ISAConstants.feetPerMeter)
        }
        return String(format: "%.0f", altM)
    }

    private func pressureString(_ p: Double) -> String {
        if p >= 10_000 { return String(format: "%.0f", p) }
        if p >= 1_000 { return String(format: "%.1f", p) }
        return String(format: "%.2f", p)
    }

    private func densityString(_ rho: Double) -> String {
        if rho >= 0.1 { return String(format: "%.4f", rho) }
        return String(format: "%.2e", rho)
    }

    private func isNearFlightLevel(_ alt: Double) -> Bool {
        flightLevels.contains(where: { abs($0 - alt) < 500 })
    }

    private enum ColumnWidth {
        case altitude, temperature, pressure, density, speed

        var value: CGFloat {
            switch self {
            case .altitude: return 58
            case .temperature: return 62
            case .pressure: return 72
            case .density: return 72
            case .speed: return 52
            }
        }
    }
}

#Preview {
    ReferenceTableView()
}
