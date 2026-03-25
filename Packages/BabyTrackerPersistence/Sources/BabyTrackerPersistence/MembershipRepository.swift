import BabyTrackerDomain
import Foundation

// MembershipRepository (core CRUD) has been moved to BabyTrackerDomain.
// This file defines the CloudKit-extended refinement used by CloudKitSyncEngine.

/// Extends MembershipRepository with CloudKit inbound sync support.
/// Only consumed by CloudKitSyncEngine — domain use cases depend on MembershipRepository directly.
@MainActor
public protocol CloudKitMembershipRepository: MembershipRepository {
    /// Saves a membership received from CloudKit without requiring an owner to already exist locally.
    /// Use this when syncing inbound data where the owner's records may not have arrived yet.
    func saveCloudKitMembership(_ membership: Membership) throws
}
