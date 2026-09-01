import Foundation

@MainActor
public struct ReorderFoodPresetsUseCase: UseCase {
    public struct Input {
        public let orderedPresetIDs: [UUID]
        public let localUserID: UUID
        public let membership: Membership

        public init(orderedPresetIDs: [UUID], localUserID: UUID, membership: Membership) {
            self.orderedPresetIDs = orderedPresetIDs
            self.localUserID = localUserID
            self.membership = membership
        }
    }

    private let repository: any FoodPresetRepository

    public init(repository: any FoodPresetRepository) {
        self.repository = repository
    }

    public func execute(_ input: Input) throws {
        guard ChildAccessPolicy.canPerform(.editEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        let updatedAt = Date.now
        for (index, id) in input.orderedPresetIDs.enumerated() {
            guard let preset = try repository.loadPreset(id: id) else { continue }
            let updated = try FoodPreset(
                id: preset.id,
                childID: preset.childID,
                foodName: preset.foodName,
                amount: preset.amount,
                unit: preset.unit,
                customUnitLabel: preset.customUnitLabel,
                sortOrder: index,
                createdAt: preset.createdAt,
                createdBy: preset.createdBy,
                updatedAt: updatedAt,
                updatedBy: input.localUserID,
                isDeleted: preset.isDeleted,
                deletedAt: preset.deletedAt
            )
            try repository.savePreset(updated)
        }
    }
}
