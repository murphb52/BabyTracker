import BabyTrackerDomain
import CloudKit
import os
import UIKit

final class CloudKitShareAppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger(subsystem: "com.adappt.BabyTracker", category: "ShareAcceptance")

    /// Route all scenes through CloudKitShareSceneDelegate so
    /// `windowScene(_:userDidAcceptCloudKitShareWith:)` is called when the user
    /// accepts a share. In scene-based apps this is the only path iOS uses —
    /// the UIApplicationDelegate equivalent is never called.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = CloudKitShareSceneDelegate.self
        return config
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        logger.info("Registered for remote notifications at launch")
        AppLogger.shared.log(.info, category: "CloudKitSync", "Registered for remote notifications at launch")
        _ = launchOptions
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        logger.info("Successfully registered for remote notifications")
        AppLogger.shared.log(.info, category: "CloudKitSync", "Successfully registered for remote notifications")
        _ = application
        _ = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        logger.error("Failed to register for remote notifications: \(error.localizedDescription, privacy: .public)")
        AppLogger.shared.log(.error, category: "CloudKitSync", "Failed to register for remote notifications: \(error.localizedDescription)")
        _ = application
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard CKNotification(fromRemoteNotificationDictionary: userInfo) != nil else {
            completionHandler(.noData)
            return
        }

        Task { @MainActor in
            guard let handler = CloudKitRemoteNotificationBridge.shared.handler else {
                completionHandler(.noData)
                return
            }

            let result = await handler()
            completionHandler(result)
        }
        _ = application
    }

    // Kept for completeness — not called in scene-based apps, but harmless.
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        let title = cloudKitShareMetadata.share[CKShare.SystemFieldKey.title] as? String ?? "unknown"
        let zone = cloudKitShareMetadata.share.recordID.zoneID.zoneName
        print("[BabyTracker][1/5] UIApplicationDelegate fired (non-scene path) — title: \(title), zone: \(zone)")
        logger.info("[1/5] UIApplicationDelegate fired (non-scene path) — title: '\(title, privacy: .private)', zone: \(zone, privacy: .public)")
        AppLogger.shared.log(.info, category: "ShareAcceptance", "[1/5] UIApplicationDelegate fired (non-scene path) — zone: \(zone)")
        CloudKitShareAcceptanceBridge.shared.handle(metadata: cloudKitShareMetadata)
    }
}
