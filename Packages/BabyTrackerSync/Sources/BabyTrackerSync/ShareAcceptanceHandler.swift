import CloudKit
import Foundation

@MainActor
public final class ShareAcceptanceHandler {
    private let syncEngine: CloudKitSyncEngine
    private let onAcceptedShare: @MainActor () -> Void

    public init(
        syncEngine: CloudKitSyncEngine,
        onAcceptedShare: @escaping @MainActor () -> Void
    ) {
        self.syncEngine = syncEngine
        self.onAcceptedShare = onAcceptedShare
    }

    public func accept(metadata: CKShare.Metadata) {
        Task { @MainActor in
            try? await syncEngine.accept(metadata: metadata)
            onAcceptedShare()
        }
    }
}
