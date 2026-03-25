import Foundation

/// Persistence operations for child membership records.
@MainActor
public protocol MembershipRepository: AnyObject {
    func loadMemberships(for childID: UUID) throws -> [Membership]
    func saveMembership(_ membership: Membership) throws
}
