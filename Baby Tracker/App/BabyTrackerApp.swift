import SwiftUI

@main
struct BabyTrackerApp: App {
    @UIApplicationDelegateAdaptor(CloudKitShareAppDelegate.self) private var appDelegate
    private let container: AppContainer

    init() {
        let container = AppContainer.live
        self.container = container
        CloudKitShareAcceptanceBridge.shared.handler = container.shareAcceptanceHandler
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(container: container)
        }
    }
}
