import Foundation

public enum MembershipValidator {
    public static func validateOwnerMemberships(
        _ memberships: [Membership]
    ) throws {
        let activeOwners = memberships.filter { membership in
            membership.role == .owner && membership.status == .active
        }

        if activeOwners.isEmpty {
            throw ChildProfileValidationError.missingOwner
        }

        if activeOwners.count > 1 {
            throw ChildProfileValidationError.duplicateOwner
        }
    }

    public static func validateRemoval(
        of membership: Membership,
        within memberships: [Membership]
    ) throws {
        guard membership.role == .owner else {
            return
        }

        let activeOwners = memberships.filter { existingMembership in
            existingMembership.role == .owner &&
            existingMembership.status == .active &&
            existingMembership.id != membership.id
        }

        if activeOwners.isEmpty {
            throw ChildProfileValidationError.cannotRemoveLastOwner
        }
    }
}
