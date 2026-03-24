import BabyTrackerDomain
import Foundation

/// Persistence operations for child membership records.
@MainActor
public protocol MembershipRepository: AnyObject {
    func loadMemberships(for childID: UUID) throws -> [Membership]
    func saveMembership(_ membership: Membership) throws
    /// Saves a membership received from CloudKit without requiring an owner to already exist locally.
    /// Use this when syncing inbound data where the owner's records may not have arrived yet.
    func saveCloudKitMembership(_ membership: Membership) throws
}
