import BabyTrackerDomain
import CloudKit
import os
import UIKit

/// Handles CloudKit share acceptance delivered via the scene lifecycle.
/// In scene-based apps (all SwiftUI apps), iOS calls `windowScene(_:userDidAcceptCloudKitShareWith:)`
/// on the UIWindowSceneDelegate rather than the UIApplicationDelegate.
final class CloudKitShareSceneDelegate: NSObject, UIWindowSceneDelegate {
    private let logger = Logger(subsystem: "com.adappt.BabyTracker", category: "ShareAcceptance")

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let metadata = connectionOptions.cloudKitShareMetadata else {
            return
        }

        let zone = metadata.share.recordID.zoneID.zoneName
        logger.info("[1/5] Scene willConnect received cold-launch share metadata for zone: \(zone, privacy: .public)")
        Task { @MainActor in
            AppLogger.shared.log(.info, category: "ShareAcceptance", "[1/5] Scene willConnect received cold-launch share metadata for zone: \(zone)")
            CloudKitShareAcceptanceBridge.shared.handle(metadata: metadata)
        }

        _ = scene
        _ = session
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        let title = cloudKitShareMetadata.share[CKShare.SystemFieldKey.title] as? String ?? "unknown"
        let zone = cloudKitShareMetadata.share.recordID.zoneID.zoneName
        print("[BabyTracker][1/5] SceneDelegate fired — title: \(title), zone: \(zone)")
        logger.info("[1/5] SceneDelegate fired — share title: '\(title, privacy: .private)', zone: \(zone, privacy: .public)")
        Task { @MainActor in
            AppLogger.shared.log(.info, category: "ShareAcceptance", "[1/5] SceneDelegate fired — zone: \(zone)")
            CloudKitShareAcceptanceBridge.shared.handle(metadata: cloudKitShareMetadata)
        }
    }
}
