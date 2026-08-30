import Foundation

@MainActor
public struct SaveFoodPresetUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let localUserID: UUID
        public let foodName: String
        public let amount: Double
        public let unit: FoodUnit
        public let customUnitLabel: String?
        public let membership: Membership

        public init(childID: UUID, localUserID: UUID, foodName: String, amount: Double, unit: FoodUnit, customUnitLabel: String?, membership: Membership) {
            self.childID = childID
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

    public func execute(_ input: Input) throws -> FoodPreset {
        guard ChildAccessPolicy.canPerform(.logEvent, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        let existing = try repository.loadPresets(for: input.childID, includingDeleted: false)
        if let match = existing.first(where: {
            $0.matches(foodName: input.foodName, amount: input.amount, unit: input.unit, customUnitLabel: input.customUnitLabel)
        }) {
            return match
        }
        let firstOrder = existing.map(\.sortOrder).min() ?? 1
        let preset = try FoodPreset(
            childID: input.childID,
            foodName: input.foodName,
            amount: input.amount,
            unit: input.unit,
            customUnitLabel: input.customUnitLabel,
            sortOrder: firstOrder - 1,
            createdBy: input.localUserID
        )
        try repository.savePreset(preset)
        return preset
    }
}
