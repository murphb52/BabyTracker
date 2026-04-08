import BabyTrackerDomain
import BabyTrackerPersistence
import CloudKit
import Foundation

/// In-memory test double for SyncStateRepository.
/// Reads sync states from the shared InMemoryStore (populated by the other InMemory* repositories
/// when they save records) and maintains its own anchor store.
@MainActor
final class InMemorySyncStateRepository: SyncStateRepository {
    private let store: InMemoryStore
    private var anchors: [String: SyncAnchor] = [:]

    init(store: InMemoryStore) {
        self.store = store
    }

    func loadPendingRecords() throws -> [SyncRecordReference] {
        store.syncStates.values
            .filter { $0.state == .pendingSync }
            .map(\.reference)
    }

    func updateSyncState(
        for record: SyncRecordReference,
        state: SyncState,
        lastSyncedAt: Date?,
        lastSyncErrorCode: String?
    ) throws {
        if store.syncStates[record.recordID] != nil {
            store.syncStates[record.recordID]?.state = state
            store.syncStates[record.recordID]?.lastSyncedAt = lastSyncedAt
            store.syncStates[record.recordID]?.lastSyncErrorCode = lastSyncErrorCode
        } else {
            store.syncStates[record.recordID] = SyncStateEntry(
                reference: record,
                state: state,
                lastSyncedAt: lastSyncedAt,
                lastSyncErrorCode: lastSyncErrorCode
            )
        }
    }

    func saveAnchor(_ anchor: SyncAnchor) throws {
        anchors[anchorKey(scope: anchor.databaseScope, zoneID: anchor.zoneID)] = anchor
    }

    func loadAnchor(databaseScope: String, zoneName: String?, ownerName: String?) throws -> SyncAnchor? {
        let scope: CKDatabase.Scope = databaseScope.contains("shared") ? .shared : .private
        let zoneID: CKRecordZone.ID? = zoneName.map {
            CKRecordZone.ID(zoneName: $0, ownerName: ownerName ?? CKCurrentUserDefaultName)
        }
        return anchors[anchorKey(scope: scope, zoneID: zoneID)]
    }

    func loadStatusSummary() throws -> SyncStatusSummary {
        let entries = Array(store.syncStates.values)
        let states = entries.map(\.state)
        let pendingCount = states.filter { $0 == .pendingSync }.count
        let lastSyncAt = entries.compactMap(\.lastSyncedAt).max()
        let lastErrorDescription = entries.compactMap(\.lastSyncErrorCode).last

        let overallState: SyncState
        if states.contains(.syncing) {
            overallState = .syncing
        } else if states.contains(.failed) {
            overallState = .failed
        } else if states.contains(.pendingSync) {
            overallState = .pendingSync
        } else {
            overallState = .upToDate
        }

        return SyncStatusSummary(
            state: overallState,
            pendingRecordCount: pendingCount,
            lastSyncAt: lastSyncAt,
            lastErrorDescription: lastErrorDescription
        )
    }

    private func anchorKey(scope: CKDatabase.Scope, zoneID: CKRecordZone.ID?) -> String {
        let scopeString = scope == .shared ? "shared" : "private"
        let zoneName = zoneID?.zoneName ?? ""
        let ownerName = zoneID?.ownerName ?? ""
        return "\(scopeString)/\(zoneName)/\(ownerName)"
    }
}
