import BabyTrackerDomain
import Foundation
import SwiftData

@MainActor
public final class SwiftDataFoodPresetRepository: FoodPresetRepository {
    private let store: BabyTrackerModelStore

    public init(store: BabyTrackerModelStore) {
        self.store = store
    }

    public func savePreset(_ preset: FoodPreset) throws {
        let existing = try fetch(id: preset.id)
        let stored = existing ?? StoredFoodPreset(
            id: preset.id,
            childID: preset.childID,
            foodName: preset.foodName,
            amount: preset.amount,
            unitRawValue: preset.unit.rawValue,
            customUnitLabel: preset.customUnitLabel,
            sortOrder: preset.sortOrder,
            createdAt: preset.createdAt,
            createdBy: preset.createdBy,
            updatedAt: preset.updatedAt,
            updatedBy: preset.updatedBy,
            isDeleted: preset.isDeleted,
            deletedAt: preset.deletedAt,
            syncStateRawValue: SyncState.pendingSync.rawValue,
            lastSyncedAt: nil,
            lastSyncErrorCode: nil
        )
        apply(preset, to: stored)
        stored.syncStateRawValue = SyncState.pendingSync.rawValue
        stored.lastSyncErrorCode = nil
        if existing == nil { modelContext.insert(stored) }
        try saveChanges()
    }

    public func loadPreset(id: UUID) throws -> FoodPreset? {
        try fetch(id: id).map(map)
    }

    public func loadPresets(for childID: UUID, includingDeleted: Bool = false) throws -> [FoodPreset] {
        let predicate: Predicate<StoredFoodPreset>
        if includingDeleted {
            predicate = #Predicate { $0.childID == childID }
        } else {
            predicate = #Predicate { $0.childID == childID && !$0.isDeleted && $0.deletedAt == nil }
        }
        return try modelContext.fetch(FetchDescriptor(predicate: predicate))
            .map(map)
            .sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
                return $0.id.uuidString < $1.id.uuidString
            }
    }

    public func softDeletePreset(id: UUID, deletedAt: Date, deletedBy: UUID) throws {
        guard let stored = try fetch(id: id) else { return }
        stored.isDeleted = true
        stored.deletedAt = deletedAt
        stored.updatedAt = deletedAt
        stored.updatedBy = deletedBy
        stored.syncStateRawValue = SyncState.pendingSync.rawValue
        stored.lastSyncErrorCode = nil
        try saveChanges()
    }

    private var modelContext: ModelContext { store.modelContainer.mainContext }

    private func fetch(id: UUID) throws -> StoredFoodPreset? {
        let predicate = #Predicate<StoredFoodPreset> { $0.id == id }
        return try modelContext.fetch(FetchDescriptor(predicate: predicate)).first
    }

    private func map(_ stored: StoredFoodPreset) throws -> FoodPreset {
        try FoodPreset(
            id: stored.id,
            childID: stored.childID,
            foodName: stored.foodName,
            amount: stored.amount,
            unit: FoodUnit(rawValue: stored.unitRawValue) ?? .custom,
            customUnitLabel: stored.customUnitLabel,
            sortOrder: stored.sortOrder,
            createdAt: stored.createdAt,
            createdBy: stored.createdBy,
            updatedAt: stored.updatedAt,
            updatedBy: stored.updatedBy,
            isDeleted: stored.isDeleted || stored.deletedAt != nil,
            deletedAt: stored.deletedAt
        )
    }

    private func apply(_ preset: FoodPreset, to stored: StoredFoodPreset) {
        stored.childID = preset.childID
        stored.foodName = preset.foodName
        stored.amount = preset.amount
        stored.unitRawValue = preset.unit.rawValue
        stored.customUnitLabel = preset.customUnitLabel
        stored.sortOrder = preset.sortOrder
        stored.createdAt = preset.createdAt
        stored.createdBy = preset.createdBy
        stored.updatedAt = preset.updatedAt
        stored.updatedBy = preset.updatedBy
        stored.isDeleted = preset.isDeleted
        stored.deletedAt = preset.deletedAt
    }

    private func saveChanges() throws {
        if modelContext.hasChanges { try modelContext.save() }
    }
}
