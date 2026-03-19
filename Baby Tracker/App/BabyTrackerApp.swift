import SwiftUI

@main
struct BabyTrackerApp: App {
    private let container = AppContainer.live

    var body: some Scene {
        WindowGroup {
            AppRootView(container: container)
        }
    }
}
