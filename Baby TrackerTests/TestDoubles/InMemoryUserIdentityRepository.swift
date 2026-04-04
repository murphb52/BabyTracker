import BabyTrackerDomain
import Foundation

/// In-memory test double for UserIdentityRepository.
/// Tracks the local user via a stored ID in InMemoryStore rather than UserDefaults.
@MainActor
final class InMemoryUserIdentityRepository: UserIdentityRepository {
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
    }

    func loadUsers(for userIDs: [UUID]) throws -> [UserIdentity] {
        userIDs.compactMap { store.users[$0] }
    }

    func saveUser(_ user: UserIdentity) throws {
        store.users[user.id] = user
    }

    func removeLegacyPlaceholderCaregivers() throws {}

    func resetAllData() throws {
        store.users = [:]
        store.localUserID = nil
    }
}
