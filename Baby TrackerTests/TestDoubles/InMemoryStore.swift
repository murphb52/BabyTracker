import BabyTrackerDomain
import BabyTrackerPersistence
import CloudKit
import Foundation

/// Shared in-memory data context used by the InMemory* test double repositories.
/// Mirrors the role that BabyTrackerModelStore plays in production — a single shared
/// backing store that all repositories read from and write to.
@MainActor
final class InMemoryStore {
    var children: [UUID: Child] = [:]
    var memberships: [UUID: Membership] = [:]
    var events: [UUID: BabyEvent] = [:]
    var users: [UUID: UserIdentity] = [:]
    var localUserID: UUID?
    var selectedChildID: UUID?
    var syncStates: [UUID: SyncStateEntry] = [:]
    var cloudKitChildContexts: [UUID: CloudKitChildContext] = [:]
}

/// Tracks the sync state for a single record, mirroring the per-entity sync fields
/// stored on SwiftData models in production.
struct SyncStateEntry {
    let reference: SyncRecordReference
    var state: SyncState
    var lastSyncedAt: Date?
    var lastSyncErrorCode: String?
}
