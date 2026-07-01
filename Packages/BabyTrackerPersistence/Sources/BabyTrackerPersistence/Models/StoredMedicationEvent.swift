import Foundation
import SwiftData

@Model
final class StoredMedicationEvent {
    #Index<StoredMedicationEvent>([\.childID], [\.childID, \.occurredAt])

    var id: UUID = UUID()
    var childID: UUID = UUID()
    var occurredAt: Date = Date()
    var createdAt: Date = Date()
    var createdBy: UUID = UUID()
    var updatedAt: Date = Date()
    var updatedBy: UUID = UUID()
    var notes: String = ""
    var isDeleted: Bool = false
    var deletedAt: Date?
    var medicineName: String = ""
    var amount: Double = 0
    var unitRawValue: String = ""
    var customUnitLabel: String?
    var syncStateRawValue: String = ""
    var lastSyncedAt: Date?
    var lastSyncErrorCode: String?

    init(
        id: UUID,
        childID: UUID,
        occurredAt: Date,
        createdAt: Date,
        createdBy: UUID,
        updatedAt: Date,
        updatedBy: UUID,
        notes: String,
        isDeleted: Bool,
        deletedAt: Date?,
        medicineName: String,
        amount: Double,
        unitRawValue: String,
        customUnitLabel: String?,
        syncStateRawValue: String,
        lastSyncedAt: Date?,
        lastSyncErrorCode: String?
    ) {
        self.id = id
        self.childID = childID
        self.occurredAt = occurredAt
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.updatedAt = updatedAt
        self.updatedBy = updatedBy
        self.notes = notes
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.medicineName = medicineName
        self.amount = amount
        self.unitRawValue = unitRawValue
        self.customUnitLabel = customUnitLabel
        self.syncStateRawValue = syncStateRawValue
        self.lastSyncedAt = lastSyncedAt
        self.lastSyncErrorCode = lastSyncErrorCode
    }
}
