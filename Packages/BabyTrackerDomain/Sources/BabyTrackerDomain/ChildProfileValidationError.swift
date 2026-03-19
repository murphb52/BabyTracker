import Foundation

public enum ChildProfileValidationError: LocalizedError, Equatable, Sendable {
    case emptyChildName
    case emptyCaregiverName
    case duplicateOwner
    case missingOwner
    case cannotRemoveLastOwner
    case insufficientPermissions
    case invalidMembershipTransition(from: MembershipStatus, to: MembershipStatus)

    public var errorDescription: String? {
        switch self {
        case .emptyChildName:
            "Enter a child name."
        case .emptyCaregiverName:
            "Enter a caregiver name."
        case .duplicateOwner:
            "Each child profile can have only one owner."
        case .missingOwner:
            "Each child profile must have one owner."
        case .cannotRemoveLastOwner:
            "The last owner cannot be removed."
        case .insufficientPermissions:
            "You do not have permission to do that."
        case let .invalidMembershipTransition(from, to):
            "Membership cannot move from \(from.rawValue) to \(to.rawValue)."
        }
    }
}
