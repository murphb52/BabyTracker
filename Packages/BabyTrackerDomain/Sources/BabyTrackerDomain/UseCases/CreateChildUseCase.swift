import Foundation

@MainActor
public struct CreateChildUseCase: UseCase {
    public struct Input {
        public let name: String
        public let birthDate: Date?
        public let localUser: UserIdentity

        public init(name: String, birthDate: Date?, localUser: UserIdentity) {
            self.name = name
            self.birthDate = birthDate
            self.localUser = localUser
        }
    }

    private let childRepository: any ChildRepository
    private let membershipRepository: any MembershipRepository
    private let childSelectionStore: any ChildSelectionStore

    public init(
        childRepository: any ChildRepository,
        membershipRepository: any MembershipRepository,
        childSelectionStore: any ChildSelectionStore
    ) {
        self.childRepository = childRepository
        self.membershipRepository = membershipRepository
        self.childSelectionStore = childSelectionStore
    }

    public func execute(_ input: Input) throws -> Child {
        let child = try Child(
            name: input.name,
            birthDate: input.birthDate,
            createdBy: input.localUser.id
        )
        let ownerMembership = Membership.owner(
            childID: child.id,
            userID: input.localUser.id,
            createdAt: child.createdAt
        )

        try childRepository.saveChild(child)
        try membershipRepository.saveMembership(ownerMembership)
        childSelectionStore.saveSelectedChildID(child.id)
        return child
    }
}
