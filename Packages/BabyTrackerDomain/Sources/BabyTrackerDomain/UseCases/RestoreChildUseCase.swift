import Foundation

@MainActor
public struct RestoreChildUseCase: UseCase {
    public struct Input {
        public let childID: UUID

        public init(childID: UUID) {
            self.childID = childID
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

    public func execute(_ input: Input) throws -> Child {
        guard var restoredChild = try childRepository.loadChild(id: input.childID) else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        restoredChild.isArchived = false
        try childRepository.saveChild(restoredChild)
        childSelectionStore.saveSelectedChildID(input.childID)
        return restoredChild
    }
}
