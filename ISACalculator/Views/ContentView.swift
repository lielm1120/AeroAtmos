import SwiftUI

struct ContentView: View {
    @Environment(AtmosphereViewModel.self) private var viewModel

    var body: some View {
        TabView {
            CalculatorScreen()
                .tabItem {
                    Label(String(localized: "Calculator"), systemImage: "function")
                }

            AtmosphereChartView()
                .tabItem {
                    Label(String(localized: "Profile"), systemImage: "chart.xyaxis.line")
                }

            DensityAltitudeView()
                .tabItem {
                    Label(String(localized: "Density Alt"), systemImage: "airplane.circle")
                }

            ReferenceView()
                .tabItem {
                    Label(String(localized: "Reference"), systemImage: "book.closed")
                }

            LiveBarometerView()
                .tabItem {
                    Label(String(localized: "Live"), systemImage: "barometer")
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
