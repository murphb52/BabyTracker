import BabyTrackerDomain
import Foundation
import SwiftData

@MainActor
public final class SwiftDataChildProfileRepository: ChildProfileRepository {
    private enum DefaultsKey {
        static let localUserID = "stage1.localUserID"
        static let selectedChildID = "stage1.selectedChildID"
    }

    private let modelContainer: ModelContainer
    private let userDefaults: UserDefaults

    public init(
        isStoredInMemoryOnly: Bool = false,
        userDefaults: UserDefaults = .standard
    ) throws {
        let schema = Schema([
            StoredUserIdentity.self,
            StoredChild.self,
            StoredMembership.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )

        self.modelContainer = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        self.userDefaults = userDefaults
    }

    public func loadLocalUser() throws -> UserIdentity? {
        guard let localUserID = localUserID else {
            return nil
        }

        guard let storedUser = try fetchStoredUser(id: localUserID) else {
            return nil
        }

        return try mapUser(storedUser)
    }

    public func saveLocalUser(_ user: UserIdentity) throws {
        try saveUser(user)
        userDefaults.set(user.id.uuidString, forKey: DefaultsKey.localUserID)
    }

    public func loadSelectedChildID() -> UUID? {
        guard let rawValue = userDefaults.string(forKey: DefaultsKey.selectedChildID) else {
            return nil
        }

        return UUID(uuidString: rawValue)
    }

    public func saveSelectedChildID(_ childID: UUID?) {
        userDefaults.set(childID?.uuidString, forKey: DefaultsKey.selectedChildID)
    }

    public func loadActiveChildren(for userID: UUID) throws -> [Child] {
        try loadChildren(for: userID, isArchived: false)
    }

    public func loadArchivedChildren(for userID: UUID) throws -> [Child] {
        try loadChildren(for: userID, isArchived: true)
    }

    public func loadChild(id: UUID) throws -> Child? {
        guard let storedChild = try fetchStoredChild(id: id) else {
            return nil
        }

        return try mapChild(storedChild)
    }

    public func saveChild(_ child: Child) throws {
        let existingStoredChild = try fetchStoredChild(id: child.id)
        let storedChild = existingStoredChild ?? StoredChild(
            id: child.id,
            name: child.name,
            birthDate: child.birthDate,
            createdAt: child.createdAt,
            createdBy: child.createdBy,
            isArchived: child.isArchived
        )

        storedChild.name = child.name
        storedChild.birthDate = child.birthDate
        storedChild.createdAt = child.createdAt
        storedChild.createdBy = child.createdBy
        storedChild.isArchived = child.isArchived

        if existingStoredChild == nil {
            modelContext.insert(storedChild)
        }

        try saveChanges()
    }

    public func loadMemberships(for childID: UUID) throws -> [Membership] {
        let storedMemberships = try modelContext.fetch(FetchDescriptor<StoredMembership>())
        let memberships = try storedMemberships
            .filter { membership in membership.childID == childID }
            .map(mapMembership)

        return memberships.sorted(by: sortMemberships)
    }

    public func saveMembership(_ membership: Membership) throws {
        var memberships = try loadMemberships(for: membership.childID)
        memberships.removeAll { existingMembership in
            existingMembership.id == membership.id
        }
        memberships.append(membership)

        try MembershipValidator.validateOwnerMemberships(memberships)

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

        if existingStoredMembership == nil {
            modelContext.insert(storedMembership)
        }

        try saveChanges()
    }

    public func loadUsers(for userIDs: [UUID]) throws -> [UserIdentity] {
        let requestedIDs = Set(userIDs)
        let storedUsers = try modelContext.fetch(FetchDescriptor<StoredUserIdentity>())

        return try storedUsers
            .filter { user in requestedIDs.contains(user.id) }
            .map(mapUser)
            .sorted { left, right in
                left.displayName.localizedCaseInsensitiveCompare(right.displayName) == .orderedAscending
            }
    }

    public func saveUser(_ user: UserIdentity) throws {
        let existingStoredUser = try fetchStoredUser(id: user.id)
        let storedUser = existingStoredUser ?? StoredUserIdentity(
            id: user.id,
            displayName: user.displayName,
            createdAt: user.createdAt,
            cloudKitUserRecordName: user.cloudKitUserRecordName
        )

        storedUser.displayName = user.displayName
        storedUser.createdAt = user.createdAt
        storedUser.cloudKitUserRecordName = user.cloudKitUserRecordName

        if existingStoredUser == nil {
            modelContext.insert(storedUser)
        }

        try saveChanges()
    }

    public func resetAllData() throws {
        try deleteAll(StoredMembership.self)
        try deleteAll(StoredChild.self)
        try deleteAll(StoredUserIdentity.self)
        userDefaults.removeObject(forKey: DefaultsKey.localUserID)
        userDefaults.removeObject(forKey: DefaultsKey.selectedChildID)
    }

    private var modelContext: ModelContext {
        modelContainer.mainContext
    }

    private var localUserID: UUID? {
        guard let rawValue = userDefaults.string(forKey: DefaultsKey.localUserID) else {
            return nil
        }

        return UUID(uuidString: rawValue)
    }

    private func loadChildren(
        for userID: UUID,
        isArchived: Bool
    ) throws -> [Child] {
        let memberships = try modelContext.fetch(FetchDescriptor<StoredMembership>())
        let activeChildIDs = Set(
            memberships
                .filter { membership in
                    membership.userID == userID &&
                    membership.statusRawValue == MembershipStatus.active.rawValue
                }
                .map(\.childID)
        )

        let storedChildren = try modelContext.fetch(FetchDescriptor<StoredChild>())

        return try storedChildren
            .filter { child in
                activeChildIDs.contains(child.id) && child.isArchived == isArchived
            }
            .map(mapChild)
            .sorted { left, right in
                left.createdAt < right.createdAt
            }
    }

    private func fetchStoredChild(id: UUID) throws -> StoredChild? {
        try modelContext.fetch(FetchDescriptor<StoredChild>()).first(where: { child in
            child.id == id
        })
    }

    private func fetchStoredMembership(id: UUID) throws -> StoredMembership? {
        try modelContext.fetch(FetchDescriptor<StoredMembership>()).first(where: { membership in
            membership.id == id
        })
    }

    private func fetchStoredUser(id: UUID) throws -> StoredUserIdentity? {
        try modelContext.fetch(FetchDescriptor<StoredUserIdentity>()).first(where: { user in
            user.id == id
        })
    }

    private func mapChild(_ storedChild: StoredChild) throws -> Child {
        try Child(
            id: storedChild.id,
            name: storedChild.name,
            birthDate: storedChild.birthDate,
            createdAt: storedChild.createdAt,
            createdBy: storedChild.createdBy,
            isArchived: storedChild.isArchived
        )
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

    private func mapUser(_ storedUser: StoredUserIdentity) throws -> UserIdentity {
        try UserIdentity(
            id: storedUser.id,
            displayName: storedUser.displayName,
            createdAt: storedUser.createdAt,
            cloudKitUserRecordName: storedUser.cloudKitUserRecordName
        )
    }

    private func saveChanges() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    private func sortMemberships(
        _ left: Membership,
        _ right: Membership
    ) -> Bool {
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

    private func deleteAll<T: PersistentModel>(_ modelType: T.Type) throws {
        let models = try modelContext.fetch(FetchDescriptor<T>())

        for model in models {
            modelContext.delete(model)
        }

        try saveChanges()
    }
}
