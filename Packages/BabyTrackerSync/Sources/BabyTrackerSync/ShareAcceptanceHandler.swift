import BabyTrackerDomain
import CloudKit
import Foundation
import os

@MainActor
public final class ShareAcceptanceHandler {
    private let syncEngine: CloudKitSyncEngine
    private let onStartAcceptingShare: @MainActor () -> Void
    private let onAcceptedShare: @MainActor () -> Void
    private let onFailedToAcceptShare: @MainActor (Error) -> Void
    private let logger = Logger(subsystem: "com.adappt.BabyTracker", category: "ShareAcceptance")

    public init(
        syncEngine: CloudKitSyncEngine,
        onStartAcceptingShare: @escaping @MainActor () -> Void,
        onAcceptedShare: @escaping @MainActor () -> Void,
        onFailedToAcceptShare: @escaping @MainActor (Error) -> Void
    ) {
        self.syncEngine = syncEngine
        self.onStartAcceptingShare = onStartAcceptingShare
        self.onAcceptedShare = onAcceptedShare
        self.onFailedToAcceptShare = onFailedToAcceptShare
    }

    public func accept(metadata: CKShare.Metadata) {
        print("[BabyTracker][3/5] ShareAcceptanceHandler.accept called")
        logger.info("[3/5] ShareAcceptanceHandler queuing accept task")
        AppLogger.shared.log(.info, category: "ShareAcceptance", "[3/5] ShareAcceptanceHandler queuing accept task")
        Task { @MainActor in
            onStartAcceptingShare()
            print("[BabyTracker][3/5] ShareAcceptanceHandler task running — calling sync engine")
            logger.info("[3/5] ShareAcceptanceHandler task started — calling sync engine")
            AppLogger.shared.log(.info, category: "ShareAcceptance", "[3/5] ShareAcceptanceHandler task started — calling sync engine")
            do {
                try await syncEngine.accept(metadata: metadata)
                print("[BabyTracker][3/5] Sync engine accept returned — calling onAcceptedShare callback")
                logger.info("[3/5] Sync engine accept returned — calling onAcceptedShare callback")
                AppLogger.shared.log(.info, category: "ShareAcceptance", "[3/5] Sync engine accept returned — calling onAcceptedShare callback")
                onAcceptedShare()
            } catch {
                print("[BabyTracker][3/5] Sync engine accept FAILED: \(error)")
                logger.error("[3/5] Sync engine accept failed: \(error.localizedDescription, privacy: .public)")
                AppLogger.shared.log(.error, category: "ShareAcceptance", "[3/5] Sync engine accept failed: \(error.localizedDescription)")
                onFailedToAcceptShare(error)
            }
        }
    }
}
