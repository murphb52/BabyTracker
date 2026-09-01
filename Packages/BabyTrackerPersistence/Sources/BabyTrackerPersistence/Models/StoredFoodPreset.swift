import Foundation
import SwiftData

@Model
final class StoredFoodPreset {
    #Index<StoredFoodPreset>([\.childID], [\.childID, \.sortOrder])

    var id: UUID = UUID()
    var childID: UUID = UUID()
    var foodName: String = ""
    var amount: Double = 0
    var unitRawValue: String = ""
    var customUnitLabel: String?
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var createdBy: UUID = UUID()
    var updatedAt: Date = Date()
    var updatedBy: UUID = UUID()
    var isDeleted: Bool = false
    var deletedAt: Date?
    var syncStateRawValue: String = ""
    var lastSyncedAt: Date?
    var lastSyncErrorCode: String?

    init(id: UUID, childID: UUID, foodName: String, amount: Double, unitRawValue: String, customUnitLabel: String?, sortOrder: Int, createdAt: Date, createdBy: UUID, updatedAt: Date, updatedBy: UUID, isDeleted: Bool, deletedAt: Date?, syncStateRawValue: String, lastSyncedAt: Date?, lastSyncErrorCode: String?) {
        self.id = id
        self.childID = childID
        self.foodName = foodName
        self.amount = amount
        self.unitRawValue = unitRawValue
        self.customUnitLabel = customUnitLabel
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.updatedAt = updatedAt
        self.updatedBy = updatedBy
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.syncStateRawValue = syncStateRawValue
        self.lastSyncedAt = lastSyncedAt
        self.lastSyncErrorCode = lastSyncErrorCode
    }
}
