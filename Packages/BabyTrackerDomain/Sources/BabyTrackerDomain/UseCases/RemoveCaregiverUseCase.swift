import Foundation

@MainActor
public struct RemoveCaregiverUseCase: UseCase {
    public struct Input {
        public let membershipID: UUID
        public let childID: UUID
        public let actingMembership: Membership

        public init(membershipID: UUID, childID: UUID, actingMembership: Membership) {
            self.membershipID = membershipID
            self.childID = childID
            self.actingMembership = actingMembership
        }
    }

    private let membershipRepository: any MembershipRepository

    public init(membershipRepository: any MembershipRepository) {
        self.membershipRepository = membershipRepository
    }

    /// Returns the removed membership so the caller can trigger the async CloudKit participant removal.
    public func execute(_ input: Input) throws -> Membership {
        guard ChildAccessPolicy.canPerform(.removeCaregiver, membership: input.actingMembership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        let allMemberships = try membershipRepository.loadMemberships(for: input.childID)

        guard let membership = allMemberships.first(where: { $0.id == input.membershipID }) else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        try MembershipValidator.validateRemoval(of: membership, within: allMemberships)
        let removedMembership = try membership.removed()
        try membershipRepository.saveMembership(removedMembership)
        return removedMembership
    }
}
