import Foundation

/// The CloudKit operation the caller should perform before purging local data.
public enum HardDeleteChildIntent: Sendable {
    /// User is the zone owner — caller should delete the private CloudKit zone.
    case deleteOwnedZone
    /// User is a caregiver — caller should leave the shared CloudKit zone.
    case leaveCaregiverShare
}

/// Validates that the acting user has an active membership and returns the
/// appropriate CloudKit cleanup intent based on their role.
///
/// This use case has no side effects. The caller is responsible for:
/// 1. Performing the async CloudKit operation indicated by the returned intent.
/// 2. Calling `childRepository.purgeChildData(id:)` to remove local data.
@MainActor
public struct HardDeleteChildUseCase: UseCase {
    public struct Input {
        public let membership: Membership

        public init(membership: Membership) {
            self.membership = membership
        }
    }

    public typealias Output = HardDeleteChildIntent

    public init() {}

    public func execute(_ input: Input) throws -> HardDeleteChildIntent {
        guard input.membership.status == .active else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        return input.membership.role == .owner ? .deleteOwnedZone : .leaveCaregiverShare
    }
}
