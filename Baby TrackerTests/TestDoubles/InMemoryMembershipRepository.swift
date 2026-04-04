import BabyTrackerDomain
import Foundation

/// In-memory test double for MembershipRepository.
@MainActor
final class InMemoryMembershipRepository: MembershipRepository {
    private let store: InMemoryStore

    init(store: InMemoryStore) {
        self.store = store
    }

    func loadMemberships(for childID: UUID) throws -> [Membership] {
        store.memberships.values.filter { $0.childID == childID }
    }

    func saveMembership(_ membership: Membership) throws {
        store.memberships[membership.id] = membership
    }
}
