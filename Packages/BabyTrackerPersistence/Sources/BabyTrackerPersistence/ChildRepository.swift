import BabyTrackerDomain
import Foundation

/// Persistence operations for child profiles and their associated CloudKit sync context.
@MainActor
public protocol ChildRepository: AnyObject {
    func loadAllChildren() throws -> [Child]
    func loadActiveChildren(for userID: UUID) throws -> [Child]
    func loadArchivedChildren(for userID: UUID) throws -> [Child]
    func loadChild(id: UUID) throws -> Child?
    func saveChild(_ child: Child) throws
    func loadCloudKitChildContext(id: UUID) throws -> CloudKitChildContext?
    func saveCloudKitChildContext(_ context: CloudKitChildContext) throws
    /// Deletes all data associated with a child (memberships, events, the child record itself).
    func purgeChildData(id: UUID) throws
}
