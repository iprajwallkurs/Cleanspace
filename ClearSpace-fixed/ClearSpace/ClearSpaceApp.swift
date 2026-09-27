import SwiftUI

@main
struct ClearSpaceApp: App {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
