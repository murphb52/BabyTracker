import BabyTrackerSync
import CloudKit
import Foundation
import os

@MainActor
final class CloudKitShareAcceptanceBridge {
    static let shared = CloudKitShareAcceptanceBridge()

    var handler: ShareAcceptanceHandler? {
        didSet {
            guard let handler, let queued = queuedMetadata else { return }
            print("[BabyTracker][2/5] Handler set — flushing queued share metadata")
            logger.info("[2/5] Handler set — flushing queued share metadata")
            queuedMetadata = nil
            handler.accept(metadata: queued)
        }
    }

    private var queuedMetadata: CKShare.Metadata?
    private let logger = Logger(subsystem: "com.adappt.BabyTracker", category: "ShareAcceptance")

    private init() {}

    func handle(metadata: CKShare.Metadata) {
        print("[BabyTracker][2/5] Bridge.handle called — handler is \(handler == nil ? "nil (queuing)" : "ready")")
        logger.info("[2/5] Bridge.handle called — handler is \(self.handler == nil ? "nil (queuing)" : "ready", privacy: .public)")
        guard let handler else {
            logger.warning("[2/5] Handler not set yet — queuing metadata for when handler is assigned")
            queuedMetadata = metadata
            return
        }
        logger.info("[2/5] Forwarding share metadata to ShareAcceptanceHandler")
        handler.accept(metadata: metadata)
    }
}
