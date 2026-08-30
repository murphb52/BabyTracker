import Foundation

@MainActor
public struct UpdateFoodPresetUseCase: UseCase {
    public struct Input {
        public let presetID: UUID
        public let localUserID: UUID
        public let foodName: String
        public let amount: Double
        public let unit: FoodUnit
        public let customUnitLabel: String?
        public let membership: Membership

        public init(presetID: UUID, localUserID: UUID, foodName: String, amount: Double, unit: FoodUnit, customUnitLabel: String?, membership: Membership) {
            self.presetID = presetID
            self.localUserID = localUserID
            self.foodName = foodName
            self.amount = amount
            self.unit = unit
            self.customUnitLabel = customUnitLabel
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
        guard let current = try repository.loadPreset(id: input.presetID) else { return }
        let updated = try FoodPreset(
            id: current.id,
            childID: current.childID,
            foodName: input.foodName,
            amount: input.amount,
            unit: input.unit,
            customUnitLabel: input.customUnitLabel,
            sortOrder: current.sortOrder,
            createdAt: current.createdAt,
            createdBy: current.createdBy,
            updatedAt: .now,
            updatedBy: input.localUserID,
            isDeleted: current.isDeleted,
            deletedAt: current.deletedAt
        )
        try repository.savePreset(updated)
    }
}
