import BabyTrackerDomain
import Foundation

// ChildRepository (core CRUD) has been moved to BabyTrackerDomain.
// This file defines the CloudKit-extended refinement used by CloudKitSyncEngine.

/// Extends ChildRepository with CloudKit zone context persistence.
/// Only consumed by CloudKitSyncEngine — domain use cases depend on ChildRepository directly.
@MainActor
public protocol CloudKitChildRepository: ChildRepository {
    func loadCloudKitChildContext(id: UUID) throws -> CloudKitChildContext?
    func saveCloudKitChildContext(_ context: CloudKitChildContext) throws
}
