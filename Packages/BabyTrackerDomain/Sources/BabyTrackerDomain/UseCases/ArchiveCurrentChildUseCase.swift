import Foundation

@MainActor
public struct ArchiveCurrentChildUseCase: UseCase {
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
    private let childSelectionStore: any ChildSelectionStore

    public init(
        childRepository: any ChildRepository,
        childSelectionStore: any ChildSelectionStore
    ) {
        self.childRepository = childRepository
        self.childSelectionStore = childSelectionStore
    }

    public func execute(_ input: Input) throws -> Void {
        guard ChildAccessPolicy.canPerform(.archiveChild, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        var archivedChild = input.child
        archivedChild.isArchived = true
        try childRepository.saveChild(archivedChild)

        if input.currentSelectedChildID == archivedChild.id {
            childSelectionStore.saveSelectedChildID(nil)
        }
    }
}
