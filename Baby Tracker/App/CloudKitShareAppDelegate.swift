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
