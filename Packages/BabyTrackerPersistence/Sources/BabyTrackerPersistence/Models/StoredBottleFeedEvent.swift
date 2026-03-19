import Foundation
import SwiftData

@Model
final class StoredBottleFeedEvent {
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
    var amountMilliliters: Int = 0
    var milkTypeRawValue: String?
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
        amountMilliliters: Int,
        milkTypeRawValue: String?,
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
        self.amountMilliliters = amountMilliliters
        self.milkTypeRawValue = milkTypeRawValue
        self.syncStateRawValue = syncStateRawValue
        self.lastSyncedAt = lastSyncedAt
        self.lastSyncErrorCode = lastSyncErrorCode
    }
}
