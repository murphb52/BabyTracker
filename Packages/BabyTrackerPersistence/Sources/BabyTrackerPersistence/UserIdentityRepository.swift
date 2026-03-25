import BabyTrackerDomain
import Foundation

// UserIdentityRepository (core operations) has been moved to BabyTrackerDomain.
// This file defines the CloudKit-extended refinement used by CloudKitSyncEngine.

/// Extends UserIdentityRepository with CloudKit user record linking.
/// Only consumed by CloudKitSyncEngine — domain use cases depend on UserIdentityRepository directly.
@MainActor
public protocol CloudKitUserIdentityRepository: UserIdentityRepository {
    func linkLocalUser(toCloudKitUserRecordName recordName: String) throws -> UserIdentity?
}
