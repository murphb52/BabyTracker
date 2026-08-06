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

            // Report accurately. iOS uses how often a wake-up actually produced
            // new data to decide how often to keep delivering silent pushes, so
            // claiming `.newData` for an empty sync costs future deliveries.
            guard summary.state != .failed else {
                return .failed
            }
            return summary.didApplyRemoteChanges ? .newData : .noData
        }
        try? Tips.configure()

        let appModel = container.appModel
        container.backgroundRefreshScheduler.registerLaunchHandler {
            await PerformBackgroundRefreshUseCase.execute(refresher: appModel)
        }

        // Arm a request at launch as well as on the background transition in
        // AppRootView. Without this, a session that is killed while in the
        // foreground leaves nothing pending with BGTaskScheduler.
        container.backgroundRefreshScheduler.scheduleNext()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(container: container)
        }
    }
}
