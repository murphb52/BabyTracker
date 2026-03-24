import BabyTrackerDomain
import Foundation
import SwiftData

@MainActor
public final class SwiftDataMembershipRepository: MembershipRepository {
    private let store: BabyTrackerModelStore

    public init(store: BabyTrackerModelStore) {
        self.store = store
    }

    public func loadMemberships(for childID: UUID) throws -> [Membership] {
        try modelContext.fetch(FetchDescriptor<StoredMembership>())
            .filter { $0.childID == childID }
            .map(mapMembership)
            .sorted(by: sortMemberships)
    }

    public func saveMembership(_ membership: Membership) throws {
        var memberships = try loadMemberships(for: membership.childID)
        memberships.removeAll { existingMembership in
            existingMembership.id == membership.id
        }
        memberships.append(membership)

        try MembershipValidator.validateOwnerMemberships(memberships)

        try upsertMembership(membership)
    }

    public func saveCloudKitMembership(_ membership: Membership) throws {
        try upsertMembership(membership)
    }

    private var modelContext: ModelContext {
        store.modelContainer.mainContext
    }

    private func fetchStoredMembership(id: UUID) throws -> StoredMembership? {
        try modelContext.fetch(FetchDescriptor<StoredMembership>())
            .first { $0.id == id }
    }

    private func upsertMembership(_ membership: Membership) throws {
        let existingStoredMembership = try fetchStoredMembership(id: membership.id)
        let storedMembership = existingStoredMembership ?? StoredMembership(
            id: membership.id,
            childID: membership.childID,
            userID: membership.userID,
            roleRawValue: membership.role.rawValue,
            statusRawValue: membership.status.rawValue,
            invitedAt: membership.invitedAt,
            acceptedAt: membership.acceptedAt
        )

        storedMembership.childID = membership.childID
        storedMembership.userID = membership.userID
        storedMembership.roleRawValue = membership.role.rawValue
        storedMembership.statusRawValue = membership.status.rawValue
        storedMembership.invitedAt = membership.invitedAt
        storedMembership.acceptedAt = membership.acceptedAt
        markPendingSync(storedMembership, errorCode: nil)

        if existingStoredMembership == nil {
            modelContext.insert(storedMembership)
        }

        try saveChanges()
    }

    private func mapMembership(_ storedMembership: StoredMembership) throws -> Membership {
        guard let role = MembershipRole(rawValue: storedMembership.roleRawValue),
              let status = MembershipStatus(rawValue: storedMembership.statusRawValue) else {
            throw ChildProfileValidationError.invalidMembershipTransition(
                from: .removed,
                to: .removed
            )
        }

        return Membership(
            id: storedMembership.id,
            childID: storedMembership.childID,
            userID: storedMembership.userID,
            role: role,
            status: status,
            invitedAt: storedMembership.invitedAt,
            acceptedAt: storedMembership.acceptedAt
        )
    }

    private func saveChanges() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    private func sortMemberships(_ left: Membership, _ right: Membership) -> Bool {
        let leftPriority = sortPriority(for: left)
        let rightPriority = sortPriority(for: right)

        if leftPriority == rightPriority {
            return left.invitedAt < right.invitedAt
        }

        return leftPriority < rightPriority
    }

    private func sortPriority(for membership: Membership) -> Int {
        if membership.role == .owner {
            return 0
        }

        switch membership.status {
        case .active:
            return 1
        case .invited:
            return 2
        case .removed:
            return 3
        }
    }

    private func markPendingSync(_ storedModel: StoredMembership, errorCode: String?) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }
}
