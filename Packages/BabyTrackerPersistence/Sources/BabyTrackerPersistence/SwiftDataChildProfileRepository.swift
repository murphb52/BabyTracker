import BabyTrackerDomain
import CloudKit
import Foundation
import SwiftData

@MainActor
public final class SwiftDataChildProfileRepository: ChildProfileRepository {
    private enum DefaultsKey {
        static let localUserID = "stage1.localUserID"
        static let selectedChildID = "stage1.selectedChildID"
    }

    private let store: BabyTrackerModelStore
    private let userDefaults: UserDefaults

    public init(
        store: BabyTrackerModelStore,
        userDefaults: UserDefaults = .standard
    ) {
        self.store = store
        self.userDefaults = userDefaults
    }

    public convenience init(
        isStoredInMemoryOnly: Bool = false,
        userDefaults: UserDefaults = .standard
    ) throws {
        let store = try BabyTrackerModelStore(
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )
        self.init(store: store, userDefaults: userDefaults)
    }

    public func loadLocalUser() throws -> UserIdentity? {
        guard let localUserID else {
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

    public func loadAllChildren() throws -> [Child] {
        try modelContext.fetch(FetchDescriptor<StoredChild>())
            .map(mapChild)
            .sorted(by: sortChildren)
    }

    public func loadCloudKitChildContext(id: UUID) throws -> CloudKitChildContext? {
        guard let storedChild = try fetchStoredChild(id: id),
              let zoneName = storedChild.cloudKitZoneName,
              let ownerName = storedChild.cloudKitZoneOwnerName,
              let databaseScopeRawValue = storedChild.cloudKitDatabaseScopeRawValue else {
            return nil
        }

        return CloudKitChildContext(
            childID: id,
            zoneID: CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName),
            shareRecordName: storedChild.cloudKitShareRecordName,
            databaseScope: databaseScopeRawValue == "shared" ? .shared : .private
        )
    }

    public func saveCloudKitChildContext(_ context: CloudKitChildContext) throws {
        guard let storedChild = try fetchStoredChild(id: context.childID) else {
            return
        }

        storedChild.cloudKitZoneName = context.zoneID.zoneName
        storedChild.cloudKitZoneOwnerName = context.zoneID.ownerName
        storedChild.cloudKitShareRecordName = context.shareRecordName
        storedChild.cloudKitDatabaseScopeRawValue = context.databaseScope == .shared ? "shared" : "private"
        try saveChanges()
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
        markPendingSync(
            storedChild,
            errorCode: nil
        )

        if existingStoredChild == nil {
            modelContext.insert(storedChild)
        }

        try saveChanges()
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

    public func loadUsers(for userIDs: [UUID]) throws -> [UserIdentity] {
        let requestedIDs = Set(userIDs)

        return try modelContext.fetch(FetchDescriptor<StoredUserIdentity>())
            .filter { requestedIDs.contains($0.id) }
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
        markPendingSync(storedUser, errorCode: nil)

        if existingStoredUser == nil {
            modelContext.insert(storedUser)
        }

        try saveChanges()
    }

    public func linkLocalUser(toCloudKitUserRecordName recordName: String) throws -> UserIdentity? {
        guard let localUser = try loadLocalUser() else {
            return nil
        }

        let normalizedRecordName = recordName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedRecordName.isEmpty else {
            return localUser
        }

        if let canonicalUser = try fetchStoredUser(cloudKitUserRecordName: normalizedRecordName),
           canonicalUser.id != localUser.id {
            try migrateUserReferences(
                from: localUser.id,
                to: canonicalUser.id
            )

            canonicalUser.displayName = localUser.displayName
            canonicalUser.cloudKitUserRecordName = normalizedRecordName
            markPendingSync(canonicalUser, errorCode: nil)

            if let duplicate = try fetchStoredUser(id: localUser.id) {
                modelContext.delete(duplicate)
            }

            userDefaults.set(canonicalUser.id.uuidString, forKey: DefaultsKey.localUserID)
            try saveChanges()
            return try mapUser(canonicalUser)
        }

        var linkedUser = localUser
        linkedUser = try linkedUser.updating(
            displayName: linkedUser.displayName,
            cloudKitUserRecordName: normalizedRecordName
        )
        try saveLocalUser(linkedUser)
        return linkedUser
    }

    public func removeLegacyPlaceholderCaregivers() throws {
        let localUserID = localUserID
        let storedUsers = try modelContext.fetch(FetchDescriptor<StoredUserIdentity>())
        let placeholderUserIDs: Set<UUID> = Set(storedUsers.compactMap { user in
            guard user.cloudKitUserRecordName == nil,
                  user.id != localUserID else {
                return nil
            }

            return user.id
        })

        guard !placeholderUserIDs.isEmpty else {
            return
        }

        let storedMemberships = try modelContext.fetch(FetchDescriptor<StoredMembership>())
        for membership in storedMemberships where placeholderUserIDs.contains(membership.userID) && membership.roleRawValue != MembershipRole.owner.rawValue {
            modelContext.delete(membership)
        }

        try deleteUnreferencedUsers(excluding: localUserID == nil ? [] : [localUserID!])
        try saveChanges()
    }

    public func purgeChildData(id: UUID) throws {
        for membership in try modelContext.fetch(FetchDescriptor<StoredMembership>()) where membership.childID == id {
            modelContext.delete(membership)
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredBreastFeedEvent>()) where event.childID == id {
            modelContext.delete(event)
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>()) where event.childID == id {
            modelContext.delete(event)
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredSleepEvent>()) where event.childID == id {
            modelContext.delete(event)
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredNappyEvent>()) where event.childID == id {
            modelContext.delete(event)
        }

        if let child = try fetchStoredChild(id: id) {
            modelContext.delete(child)
        }

        try deleteUnreferencedUsers(excluding: localUserID == nil ? [] : [localUserID!])

        if loadSelectedChildID() == id {
            saveSelectedChildID(nil)
        }

        try saveChanges()
    }

    public func resetAllData() throws {
        try deleteAll(StoredMembership.self)
        try deleteAll(StoredChild.self)
        try deleteAll(StoredUserIdentity.self)
        try deleteAll(StoredBreastFeedEvent.self)
        try deleteAll(StoredBottleFeedEvent.self)
        try deleteAll(StoredSleepEvent.self)
        try deleteAll(StoredNappyEvent.self)
        try deleteAll(StoredSyncAnchor.self)
        userDefaults.removeObject(forKey: DefaultsKey.localUserID)
        userDefaults.removeObject(forKey: DefaultsKey.selectedChildID)
    }

    private var modelContext: ModelContext {
        store.modelContainer.mainContext
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
        let activeChildIDs = Set(
            try modelContext.fetch(FetchDescriptor<StoredMembership>())
                .filter { membership in
                    membership.userID == userID &&
                    membership.statusRawValue == MembershipStatus.active.rawValue
                }
                .map(\.childID)
        )

        return try modelContext.fetch(FetchDescriptor<StoredChild>())
            .filter { child in
                activeChildIDs.contains(child.id) && child.isArchived == isArchived
            }
            .map(mapChild)
            .sorted(by: sortChildren)
    }

    private func fetchStoredChild(id: UUID) throws -> StoredChild? {
        try modelContext.fetch(FetchDescriptor<StoredChild>())
            .first { $0.id == id }
    }

    private func fetchStoredMembership(id: UUID) throws -> StoredMembership? {
        try modelContext.fetch(FetchDescriptor<StoredMembership>())
            .first { $0.id == id }
    }

    private func fetchStoredUser(id: UUID) throws -> StoredUserIdentity? {
        try modelContext.fetch(FetchDescriptor<StoredUserIdentity>())
            .first { $0.id == id }
    }

    private func fetchStoredUser(cloudKitUserRecordName: String) throws -> StoredUserIdentity? {
        try modelContext.fetch(FetchDescriptor<StoredUserIdentity>())
            .first { $0.cloudKitUserRecordName == cloudKitUserRecordName }
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

    private func sortChildren(_ left: Child, _ right: Child) -> Bool {
        left.createdAt < right.createdAt
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

    private func deleteUnreferencedUsers(excluding excludedUserIDs: [UUID]) throws {
        let excludedUserIDs = Set(excludedUserIDs)
        let referencedUserIDs = Set(
            try modelContext.fetch(FetchDescriptor<StoredMembership>())
                .map(\.userID)
        )

        let storedUsers = try modelContext.fetch(FetchDescriptor<StoredUserIdentity>())
        for user in storedUsers where !referencedUserIDs.contains(user.id) && !excludedUserIDs.contains(user.id) {
            modelContext.delete(user)
        }
    }

    private func migrateUserReferences(from sourceUserID: UUID, to targetUserID: UUID) throws {
        for child in try modelContext.fetch(FetchDescriptor<StoredChild>()) where child.createdBy == sourceUserID {
            child.createdBy = targetUserID
            markPendingSync(child, errorCode: nil)
        }

        for membership in try modelContext.fetch(FetchDescriptor<StoredMembership>()) where membership.userID == sourceUserID {
            membership.userID = targetUserID
            markPendingSync(membership, errorCode: nil)
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredBreastFeedEvent>()) {
            if event.createdBy == sourceUserID {
                event.createdBy = targetUserID
            }
            if event.updatedBy == sourceUserID {
                event.updatedBy = targetUserID
            }
            if event.createdBy == targetUserID || event.updatedBy == targetUserID {
                markPendingSync(event, errorCode: nil)
            }
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>()) {
            if event.createdBy == sourceUserID {
                event.createdBy = targetUserID
            }
            if event.updatedBy == sourceUserID {
                event.updatedBy = targetUserID
            }
            if event.createdBy == targetUserID || event.updatedBy == targetUserID {
                markPendingSync(event, errorCode: nil)
            }
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredSleepEvent>()) {
            if event.createdBy == sourceUserID {
                event.createdBy = targetUserID
            }
            if event.updatedBy == sourceUserID {
                event.updatedBy = targetUserID
            }
            if event.createdBy == targetUserID || event.updatedBy == targetUserID {
                markPendingSync(event, errorCode: nil)
            }
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredNappyEvent>()) {
            if event.createdBy == sourceUserID {
                event.createdBy = targetUserID
            }
            if event.updatedBy == sourceUserID {
                event.updatedBy = targetUserID
            }
            if event.createdBy == targetUserID || event.updatedBy == targetUserID {
                markPendingSync(event, errorCode: nil)
            }
        }
    }

    private func deleteAll<T: PersistentModel>(_ modelType: T.Type) throws {
        let models = try modelContext.fetch(FetchDescriptor<T>())

        for model in models {
            modelContext.delete(model)
        }

        try saveChanges()
    }

    private func markPendingSync(
        _ storedModel: StoredChild,
        errorCode: String?
    ) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }

    private func markPendingSync(
        _ storedModel: StoredMembership,
        errorCode: String?
    ) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }

    private func markPendingSync(
        _ storedModel: StoredUserIdentity,
        errorCode: String?
    ) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }

    private func markPendingSync(
        _ storedModel: StoredBreastFeedEvent,
        errorCode: String?
    ) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }

    private func markPendingSync(
        _ storedModel: StoredBottleFeedEvent,
        errorCode: String?
    ) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }

    private func markPendingSync(
        _ storedModel: StoredSleepEvent,
        errorCode: String?
    ) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }

    private func markPendingSync(
        _ storedModel: StoredNappyEvent,
        errorCode: String?
    ) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }
}
