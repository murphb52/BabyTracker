import SwiftUI
import TipKit
import UIKit
import BabyTrackerDomain
import BabyTrackerFeature

@main
struct BabyTrackerApp: App {
    @UIApplicationDelegateAdaptor(CloudKitShareAppDelegate.self) private var appDelegate
    private let container: AppContainer

    init() {
        let container = AppContainer.live
        self.container = container
        CloudKitShareAcceptanceBridge.shared.handler = container.shareAcceptanceHandler
        CloudKitRemoteNotificationBridge.shared.handler = {
            let summary = await container.appModel.refreshAfterRemoteNotification()
            return summary.state == .failed ? .failed : .newData
        }
        try? Tips.configure()

        let appModel = container.appModel
        container.backgroundRefreshScheduler.registerLaunchHandler {
            await PerformBackgroundRefreshUseCase.execute(refresher: appModel)
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(container: container)
        }
    }
}
