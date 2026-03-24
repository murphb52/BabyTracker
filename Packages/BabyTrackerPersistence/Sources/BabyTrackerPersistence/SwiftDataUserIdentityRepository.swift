import BabyTrackerDomain
import Foundation
import SwiftData

@MainActor
public final class SwiftDataUserIdentityRepository: UserIdentityRepository {
    private enum DefaultsKey {
        static let localUserID = "stage1.localUserID"
    }

    private let store: BabyTrackerModelStore
    private let userDefaults: UserDefaults

    public init(store: BabyTrackerModelStore, userDefaults: UserDefaults = .standard) {
        self.store = store
        self.userDefaults = userDefaults
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
            try migrateUserReferences(from: localUser.id, to: canonicalUser.id)

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

    /// Resets all stored data across all entity types and clears user defaults.
    /// Intended for development seeding and test setup only.
    public func resetAllData(clearingUserDefaults additionalUserDefaults: UserDefaults? = nil) throws {
        try deleteAll(StoredMembership.self)
        try deleteAll(StoredChild.self)
        try deleteAll(StoredUserIdentity.self)
        try deleteAll(StoredBreastFeedEvent.self)
        try deleteAll(StoredBottleFeedEvent.self)
        try deleteAll(StoredSleepEvent.self)
        try deleteAll(StoredNappyEvent.self)
        try deleteAll(StoredSyncAnchor.self)
        userDefaults.removeObject(forKey: DefaultsKey.localUserID)
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

    private func fetchStoredUser(id: UUID) throws -> StoredUserIdentity? {
        try modelContext.fetch(FetchDescriptor<StoredUserIdentity>())
            .first { $0.id == id }
    }

    private func fetchStoredUser(cloudKitUserRecordName: String) throws -> StoredUserIdentity? {
        try modelContext.fetch(FetchDescriptor<StoredUserIdentity>())
            .first { $0.cloudKitUserRecordName == cloudKitUserRecordName }
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

    private func markPendingSync(_ storedModel: StoredUserIdentity, errorCode: String?) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
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
            if event.createdBy == sourceUserID { event.createdBy = targetUserID }
            if event.updatedBy == sourceUserID { event.updatedBy = targetUserID }
            if event.createdBy == targetUserID || event.updatedBy == targetUserID {
                markPendingSync(event, errorCode: nil)
            }
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>()) {
            if event.createdBy == sourceUserID { event.createdBy = targetUserID }
            if event.updatedBy == sourceUserID { event.updatedBy = targetUserID }
            if event.createdBy == targetUserID || event.updatedBy == targetUserID {
                markPendingSync(event, errorCode: nil)
            }
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredSleepEvent>()) {
            if event.createdBy == sourceUserID { event.createdBy = targetUserID }
            if event.updatedBy == sourceUserID { event.updatedBy = targetUserID }
            if event.createdBy == targetUserID || event.updatedBy == targetUserID {
                markPendingSync(event, errorCode: nil)
            }
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredNappyEvent>()) {
            if event.createdBy == sourceUserID { event.createdBy = targetUserID }
            if event.updatedBy == sourceUserID { event.updatedBy = targetUserID }
            if event.createdBy == targetUserID || event.updatedBy == targetUserID {
                markPendingSync(event, errorCode: nil)
            }
        }
    }

    private func markPendingSync(_ storedModel: StoredChild, errorCode: String?) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }

    private func markPendingSync(_ storedModel: StoredMembership, errorCode: String?) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }

    private func markPendingSync(_ storedModel: StoredBreastFeedEvent, errorCode: String?) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }

    private func markPendingSync(_ storedModel: StoredBottleFeedEvent, errorCode: String?) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }

    private func markPendingSync(_ storedModel: StoredSleepEvent, errorCode: String?) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }

    private func markPendingSync(_ storedModel: StoredNappyEvent, errorCode: String?) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }

    private func deleteAll<T: PersistentModel>(_ modelType: T.Type) throws {
        let models = try modelContext.fetch(FetchDescriptor<T>())

        for model in models {
            modelContext.delete(model)
        }

        try saveChanges()
    }
}
