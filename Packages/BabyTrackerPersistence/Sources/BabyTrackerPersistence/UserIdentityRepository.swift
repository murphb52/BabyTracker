import BabyTrackerDomain
import Foundation

/// Persistence operations for user identity records and CloudKit user linking.
@MainActor
public protocol UserIdentityRepository: AnyObject {
    func loadLocalUser() throws -> UserIdentity?
    func saveLocalUser(_ user: UserIdentity) throws
    func loadUsers(for userIDs: [UUID]) throws -> [UserIdentity]
    func saveUser(_ user: UserIdentity) throws
    func linkLocalUser(toCloudKitUserRecordName recordName: String) throws -> UserIdentity?
    func removeLegacyPlaceholderCaregivers() throws
}
