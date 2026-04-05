import BabyTrackerDomain
import Foundation

/// Shared in-memory data context used by the InMemory* test double repositories.
/// Mirrors the role that BabyTrackerModelStore plays in production — a single shared
/// backing store that all repositories read from and write to.
@MainActor
final class InMemoryStore {
    var children: [UUID: Child] = [:]
    var memberships: [UUID: Membership] = [:]
    var events: [UUID: BabyEvent] = [:]
    var users: [UUID: UserIdentity] = [:]
    var localUserID: UUID?
    var selectedChildID: UUID?
}
