import BabyTrackerDomain
import Foundation

@MainActor
public protocol SyncStateRepository: AnyObject {
    func loadPendingRecords() throws -> [SyncRecordReference]
    func updateSyncState(
        for record: SyncRecordReference,
        state: SyncState,
        lastSyncedAt: Date?,
        lastSyncErrorCode: String?
    ) throws
    func saveAnchor(_ anchor: SyncAnchor) throws
    func loadAnchor(
        databaseScope: String,
        zoneName: String?,
        ownerName: String?
    ) throws -> SyncAnchor?
    func loadStatusSummary() throws -> SyncStatusSummary
}
