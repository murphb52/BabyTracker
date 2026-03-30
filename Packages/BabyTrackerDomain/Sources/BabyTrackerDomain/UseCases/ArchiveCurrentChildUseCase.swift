import Foundation

@MainActor
public struct ArchiveChildUseCase: UseCase {
    public struct Input {
        public let child: Child
        public let membership: Membership
        public let currentSelectedChildID: UUID?

        public init(child: Child, membership: Membership, currentSelectedChildID: UUID?) {
            self.child = child
            self.membership = membership
            self.currentSelectedChildID = currentSelectedChildID
        }
    }

    private let childRepository: any ChildRepository
    private let membershipRepository: any MembershipRepository
    private let childSelectionStore: any ChildSelectionStore
    private let hapticFeedbackProvider: any HapticFeedbackProviding

    public init(
        childRepository: any ChildRepository,
        membershipRepository: any MembershipRepository,
        childSelectionStore: any ChildSelectionStore,
        hapticFeedbackProvider: any HapticFeedbackProviding = NoOpHapticFeedbackProvider()
    ) {
        self.childRepository = childRepository
        self.membershipRepository = membershipRepository
        self.childSelectionStore = childSelectionStore
        self.hapticFeedbackProvider = hapticFeedbackProvider
    }

    /// Archives the child and revokes all active caregiver memberships.
    /// Returns the revoked memberships so the caller can remove CloudKit
    /// share participants asynchronously.
    public func execute(_ input: Input) throws -> [Membership] {
        guard ChildAccessPolicy.canPerform(.archiveChild, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        var archivedChild = input.child
        archivedChild.isArchived = true
        try childRepository.saveChild(archivedChild)

        if input.currentSelectedChildID == archivedChild.id {
            childSelectionStore.saveSelectedChildID(nil)
        }

        hapticFeedbackProvider.play(.actionSucceeded)

        let allMemberships = try membershipRepository.loadMemberships(for: input.child.id)
        var revoked: [Membership] = []
        for membership in allMemberships {
            guard membership.role == .caregiver, membership.status == .active else { continue }
            let removed = try membership.removed()
            try membershipRepository.saveMembership(removed)
            revoked.append(removed)
        }
        return revoked
    }
}
