import Foundation

/// A single dose of medication given to a child.
///
/// Records which medicine was given, how much, and in what unit. When `unit == .custom`,
/// `customUnitLabel` holds the caregiver's free-text unit (e.g. "puff", "sachet").
public struct MedicationEvent: Equatable, Identifiable, Sendable {
    public var metadata: EventMetadata
    public var medicineName: String
    public var amount: Double
    public var unit: MedicationUnit
    public var customUnitLabel: String?

    public var id: UUID {
        metadata.id
    }

    public init(
        metadata: EventMetadata,
        medicineName: String,
        amount: Double,
        unit: MedicationUnit,
        customUnitLabel: String? = nil
    ) throws {
        let trimmedName = medicineName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw BabyEventError.invalidMedicationName
        }
        guard amount > 0 else {
            throw BabyEventError.invalidMedicationAmount
        }

        self.metadata = metadata
        self.medicineName = trimmedName
        self.amount = amount
        self.unit = unit
        self.customUnitLabel = MedicationEvent.normalizedCustomLabel(customUnitLabel, unit: unit)
    }

    public func updating(
        occurredAt: Date,
        medicineName: String,
        amount: Double,
        unit: MedicationUnit,
        customUnitLabel: String?,
        updatedAt: Date = Date(),
        updatedBy: UUID
    ) throws -> MedicationEvent {
        var metadata = metadata
        metadata.occurredAt = occurredAt
        metadata.markUpdated(at: updatedAt, by: updatedBy)

        return try MedicationEvent(
            metadata: metadata,
            medicineName: medicineName,
            amount: amount,
            unit: unit,
            customUnitLabel: customUnitLabel
        )
    }

    /// The unit text to show after the amount, resolving the custom label when present.
    public var displayUnit: String {
        switch unit {
        case .custom:
            if let label = customUnitLabel, !label.isEmpty {
                return label
            }
            return MedicationUnit.custom.shortTitle
        default:
            return unit.shortTitle
        }
    }

    /// The dose amount without a trailing `.0` (e.g. "5", "2.5").
    public var formattedAmount: String {
        let rounded = (amount * 100).rounded() / 100
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(rounded)
    }

    private static func normalizedCustomLabel(_ label: String?, unit: MedicationUnit) -> String? {
        guard unit == .custom else { return nil }
        let trimmed = label?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }
}
