import SwiftUI

@main
struct ISACalculatorApp: App {
    @State private var viewModel = AtmosphereViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}
