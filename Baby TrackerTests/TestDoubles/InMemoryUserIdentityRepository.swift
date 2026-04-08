import BabyTrackerDomain
import BabyTrackerPersistence
import Foundation

/// In-memory test double for CloudKitUserIdentityRepository.
/// Tracks the local user via a stored ID in InMemoryStore rather than UserDefaults.
@MainActor
final class InMemoryUserIdentityRepository: CloudKitUserIdentityRepository {
    private let store: InMemoryStore

    init(store: InMemoryStore) {
        self.store = store
    }

    func loadLocalUser() throws -> UserIdentity? {
        guard let localUserID = store.localUserID else { return nil }
        return store.users[localUserID]
    }

    func saveLocalUser(_ user: UserIdentity) throws {
        store.users[user.id] = user
        store.localUserID = user.id
        registerPending(user)
    }

    func loadUsers(for userIDs: [UUID]) throws -> [UserIdentity] {
        userIDs.compactMap { store.users[$0] }
    }

    func saveUser(_ user: UserIdentity) throws {
        store.users[user.id] = user
        registerPending(user)
    }

    func removeLegacyPlaceholderCaregivers() throws {}

    func resetAllData() throws {
        store.users = [:]
        store.localUserID = nil
        store.children = [:]
        store.memberships = [:]
        store.events = [:]
        store.selectedChildID = nil
        store.syncStates = [:]
        store.cloudKitChildContexts = [:]
    }

    func linkLocalUser(toCloudKitUserRecordName recordName: String) throws -> UserIdentity? {
        guard var localUser = try loadLocalUser() else { return nil }
        let normalizedRecordName = recordName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedRecordName.isEmpty else { return localUser }
        localUser.cloudKitUserRecordName = normalizedRecordName
        try saveLocalUser(localUser)
        return localUser
    }

    private func registerPending(_ user: UserIdentity) {
        store.syncStates[user.id] = SyncStateEntry(
            reference: SyncRecordReference(recordType: .user, recordID: user.id),
            state: .pendingSync
        )
    }
}
