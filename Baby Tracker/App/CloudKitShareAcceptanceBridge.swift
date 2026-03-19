import BabyTrackerSync
import CloudKit
import Foundation

@MainActor
final class CloudKitShareAcceptanceBridge {
    static let shared = CloudKitShareAcceptanceBridge()

    var handler: ShareAcceptanceHandler?

    private init() {}

    func handle(metadata: CKShare.Metadata) {
        handler?.accept(metadata: metadata)
    }
}
