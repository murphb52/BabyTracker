import Foundation

public struct FoodPreset: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let childID: UUID
    public var foodName: String
    public var amount: Double
    public var unit: FoodUnit
    public var customUnitLabel: String?
    public var sortOrder: Int
    public let createdAt: Date
    public let createdBy: UUID
    public var updatedAt: Date
    public var updatedBy: UUID
    public var isDeleted: Bool
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        childID: UUID,
        foodName: String,
        amount: Double,
        unit: FoodUnit,
        customUnitLabel: String? = nil,
        sortOrder: Int,
        createdAt: Date = .now,
        createdBy: UUID,
        updatedAt: Date? = nil,
        updatedBy: UUID? = nil,
        isDeleted: Bool = false,
        deletedAt: Date? = nil
    ) throws {
        let validated = try FoodEvent(
            metadata: EventMetadata(childID: childID, occurredAt: createdAt, createdBy: createdBy),
            foodName: foodName,
            amount: amount,
            unit: unit,
            customUnitLabel: customUnitLabel
        )
        self.id = id
        self.childID = childID
        self.foodName = validated.foodName
        self.amount = validated.amount
        self.unit = validated.unit
        self.customUnitLabel = validated.customUnitLabel
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.updatedAt = updatedAt ?? createdAt
        self.updatedBy = updatedBy ?? createdBy
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
    }

    public var displayAmount: String {
        "\(FoodEvent.formattedAmount(amount)) \(unit.displayTitle(amount: amount, customLabel: customUnitLabel))"
    }

    public func matches(foodName: String, amount: Double, unit: FoodUnit, customUnitLabel: String?) -> Bool {
        let candidateCustomLabel = unit == .custom
            ? customUnitLabel?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            : nil
        return self.foodName.caseInsensitiveCompare(foodName.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
            && self.amount == amount
            && self.unit == unit
            && normalizedCustomLabel == candidateCustomLabel
    }

    public var normalizedCustomLabel: String? {
        customUnitLabel?.lowercased()
    }
}
