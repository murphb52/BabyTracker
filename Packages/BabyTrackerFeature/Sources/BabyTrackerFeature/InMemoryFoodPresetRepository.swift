import BabyTrackerDomain
import Foundation

@MainActor
public final class InMemoryFoodPresetRepository: FoodPresetRepository {
    private var presetsByID: [UUID: FoodPreset] = [:]

    public init(presets: [FoodPreset] = []) {
        presetsByID = Dictionary(uniqueKeysWithValues: presets.map { ($0.id, $0) })
    }

    public func savePreset(_ preset: FoodPreset) throws {
        presetsByID[preset.id] = preset
    }

    public func loadPreset(id: UUID) throws -> FoodPreset? {
        presetsByID[id]
    }

    public func loadPresets(for childID: UUID, includingDeleted: Bool) throws -> [FoodPreset] {
        presetsByID.values
            .filter { $0.childID == childID && (includingDeleted || !$0.isDeleted) }
            .sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
                return $0.id.uuidString < $1.id.uuidString
            }
    }

    public func softDeletePreset(id: UUID, deletedAt: Date, deletedBy: UUID) throws {
        guard let preset = presetsByID[id] else { return }
        presetsByID[id] = try FoodPreset(
            id: preset.id,
            childID: preset.childID,
            foodName: preset.foodName,
            amount: preset.amount,
            unit: preset.unit,
            customUnitLabel: preset.customUnitLabel,
            sortOrder: preset.sortOrder,
            createdAt: preset.createdAt,
            createdBy: preset.createdBy,
            updatedAt: deletedAt,
            updatedBy: deletedBy,
            isDeleted: true,
            deletedAt: deletedAt
        )
    }
}
