import Foundation

@MainActor
public struct DeleteFoodPresetUseCase: UseCase {
    public struct Input {
        public let presetID: UUID
        public let localUserID: UUID
        public let membership: Membership

        public init(presetID: UUID, localUserID: UUID, membership: Membership) {
            self.presetID = presetID
            self.localUserID = localUserID
            self.membership = membership
        }
    }

    private let repository: any FoodPresetRepository

    public init(repository: any FoodPresetRepository) {
        self.repository = repository
    }

    public func execute(_ input: Input) throws {
        guard ChildAccessPolicy.canPerform(.deleteEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        try repository.softDeletePreset(id: input.presetID, deletedAt: .now, deletedBy: input.localUserID)
    }
}
