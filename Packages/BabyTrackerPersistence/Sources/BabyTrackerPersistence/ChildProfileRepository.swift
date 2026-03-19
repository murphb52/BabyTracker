import BabyTrackerDomain
import Foundation

@MainActor
public protocol ChildProfileRepository: AnyObject {
    func loadLocalUser() throws -> UserIdentity?
    func saveLocalUser(_ user: UserIdentity) throws
    func loadSelectedChildID() -> UUID?
    func saveSelectedChildID(_ childID: UUID?)
    func loadAllChildren() throws -> [Child]
    func loadCloudKitChildContext(id: UUID) throws -> CloudKitChildContext?
    func saveCloudKitChildContext(_ context: CloudKitChildContext) throws
    func loadActiveChildren(for userID: UUID) throws -> [Child]
    func loadArchivedChildren(for userID: UUID) throws -> [Child]
    func loadChild(id: UUID) throws -> Child?
    func saveChild(_ child: Child) throws
    func loadMemberships(for childID: UUID) throws -> [Membership]
    func saveMembership(_ membership: Membership) throws
    func loadUsers(for userIDs: [UUID]) throws -> [UserIdentity]
    func saveUser(_ user: UserIdentity) throws
    func linkLocalUser(toCloudKitUserRecordName recordName: String) throws -> UserIdentity?
    func removeLegacyPlaceholderCaregivers() throws
    func purgeChildData(id: UUID) throws
}
