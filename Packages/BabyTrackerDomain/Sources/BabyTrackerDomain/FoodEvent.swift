import Foundation

public struct FoodEvent: Equatable, Identifiable, Sendable {
    public var metadata: EventMetadata
    public var foodName: String
    public var amount: Double
    public var unit: FoodUnit
    public var customUnitLabel: String?

    public var id: UUID { metadata.id }

    public init(
        metadata: EventMetadata,
        foodName: String,
        amount: Double,
        unit: FoodUnit,
        customUnitLabel: String? = nil
    ) throws {
        let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw BabyEventError.invalidFoodName }
        guard amount.isFinite, amount > 0 else { throw BabyEventError.invalidFoodAmount }

        let normalizedLabel = customUnitLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
        if unit == .custom, normalizedLabel?.isEmpty != false {
            throw BabyEventError.invalidFoodUnit
        }

        self.metadata = metadata
        self.foodName = trimmedName
        self.amount = amount
        self.unit = unit
        self.customUnitLabel = unit == .custom ? normalizedLabel : nil
    }

    public func updating(
        occurredAt: Date,
        foodName: String,
        amount: Double,
        unit: FoodUnit,
        customUnitLabel: String?,
        updatedAt: Date = .now,
        updatedBy: UUID
    ) throws -> FoodEvent {
        var metadata = metadata
        metadata.occurredAt = occurredAt
        metadata.markUpdated(at: updatedAt, by: updatedBy)
        return try FoodEvent(
            metadata: metadata,
            foodName: foodName,
            amount: amount,
            unit: unit,
            customUnitLabel: customUnitLabel
        )
    }

    public var formattedAmount: String {
        Self.formattedAmount(amount)
    }

    public var displayUnit: String {
        unit.displayTitle(amount: amount, customLabel: customUnitLabel)
    }

    public var displayAmount: String {
        "\(formattedAmount) \(displayUnit)"
    }

    public static func formattedAmount(_ amount: Double) -> String {
        let rounded = (amount * 100).rounded() / 100
        switch rounded {
        case 0.25: return "¼"
        case 0.5: return "½"
        case 0.75: return "¾"
        case 1.25: return "1¼"
        case 1.5: return "1½"
        case 1.75: return "1¾"
        case 2.5: return "2½"
        case 3.5: return "3½"
        default: break
        }
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(rounded)
    }
}
