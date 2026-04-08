import BabyTrackerDomain
import BabyTrackerPersistence
import Foundation

/// In-memory test double for CloudKitMembershipRepository.
@MainActor
final class InMemoryMembershipRepository: CloudKitMembershipRepository {
    private let store: InMemoryStore

    init(store: InMemoryStore) {
        self.store = store
    }

    func loadMemberships(for childID: UUID) throws -> [Membership] {
        store.memberships.values.filter { $0.childID == childID }
    }

    func saveMembership(_ membership: Membership) throws {
        store.memberships[membership.id] = membership
        registerPending(membership)
    }

    func saveCloudKitMembership(_ membership: Membership) throws {
        store.memberships[membership.id] = membership
        registerPending(membership)
    }

    private func registerPending(_ membership: Membership) {
        store.syncStates[membership.id] = SyncStateEntry(
            reference: SyncRecordReference(recordType: .membership, recordID: membership.id, childID: membership.childID),
            state: .pendingSync
        )
    }
}
