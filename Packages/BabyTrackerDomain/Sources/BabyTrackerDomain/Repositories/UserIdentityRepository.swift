import Foundation

/// Persistence operations for user identity records.
@MainActor
public protocol UserIdentityRepository: AnyObject {
    func loadLocalUser() throws -> UserIdentity?
    func saveLocalUser(_ user: UserIdentity) throws
    func loadUsers(for userIDs: [UUID]) throws -> [UserIdentity]
    func saveUser(_ user: UserIdentity) throws
    func removeLegacyPlaceholderCaregivers() throws
    func resetAllData() throws
}
