import BabyTrackerDomain
import BabyTrackerPersistence
import CloudKit
import Foundation

/// In-memory test double for CloudKitChildRepository.
/// Filters active/archived children by cross-referencing the shared InMemoryStore's memberships,
/// matching the behaviour of SwiftDataChildRepository.
@MainActor
final class InMemoryChildRepository: CloudKitChildRepository {
    private let store: InMemoryStore

    init(store: InMemoryStore) {
        self.store = store
    }

    func loadAllChildren() throws -> [Child] {
        store.children.values.sorted { $0.createdAt < $1.createdAt }
    }

    func loadActiveChildren(for userID: UUID) throws -> [Child] {
        let activeChildIDs = Set(
            store.memberships.values
                .filter { $0.userID == userID && $0.status == .active }
                .map(\.childID)
        )
        return store.children.values
            .filter { activeChildIDs.contains($0.id) && !$0.isArchived }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func loadArchivedChildren(for userID: UUID) throws -> [Child] {
        let childIDs = Set(
            store.memberships.values
                .filter { $0.userID == userID && $0.status == .active }
                .map(\.childID)
        )
        return store.children.values
            .filter { childIDs.contains($0.id) && $0.isArchived }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func loadChild(id: UUID) throws -> Child? {
        store.children[id]
    }

    func saveChild(_ child: Child) throws {
        store.children[child.id] = child
        store.syncStates[child.id] = SyncStateEntry(
            reference: SyncRecordReference(recordType: .child, recordID: child.id, childID: child.id),
            state: .pendingSync
        )
    }

    func purgeChildData(id: UUID) throws {
        store.children.removeValue(forKey: id)
        store.memberships = store.memberships.filter { $0.value.childID != id }
        store.events = store.events.filter { $0.value.metadata.childID != id }
        store.syncStates = store.syncStates.filter { _, entry in
            entry.reference.recordID != id && entry.reference.childID != id
        }
        store.cloudKitChildContexts.removeValue(forKey: id)
    }

    func loadCloudKitChildContext(id: UUID) throws -> CloudKitChildContext? {
        store.cloudKitChildContexts[id]
    }

    func saveCloudKitChildContext(_ context: CloudKitChildContext) throws {
        store.cloudKitChildContexts[context.childID] = context
    }
}
