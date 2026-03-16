import SwiftUI

struct ContentView: View {
    @Environment(AtmosphereViewModel.self) private var viewModel

    var body: some View {
        TabView {
            Tab(String(localized: "Calculator"), systemImage: "function") {
                CalculatorScreen()
            }
            Tab(String(localized: "Profile"), systemImage: "chart.xyaxis.line") {
                AtmosphereChartView()
            }
            Tab(String(localized: "Density Alt"), systemImage: "airplane.circle") {
                DensityAltitudeView()
            }
            Tab(String(localized: "Reference"), systemImage: "book.closed") {
                ReferenceView()
            }
            Tab(String(localized: "Live"), systemImage: "barometer") {
                LiveBarometerView()
            }
        }
        .tint(Color(hex: 0x4A90D9))
    }
}

/// Combined Reference screen with picker for Table vs Equations
struct ReferenceView: View {
    @State private var selectedPage = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedPage) {
                    Text(String(localized: "ICAO Table")).tag(0)
                    Text(String(localized: "Equations")).tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)

                if selectedPage == 0 {
                    ReferenceTableView()
                } else {
                    EquationsReferenceView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "Reference"))
                        .font(.headline)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AtmosphereViewModel())
}
