import Foundation

@MainActor
public protocol FoodPresetRepository: AnyObject {
    func savePreset(_ preset: FoodPreset) throws
    func loadPreset(id: UUID) throws -> FoodPreset?
    func loadPresets(for childID: UUID, includingDeleted: Bool) throws -> [FoodPreset]
    func softDeletePreset(id: UUID, deletedAt: Date, deletedBy: UUID) throws
}
