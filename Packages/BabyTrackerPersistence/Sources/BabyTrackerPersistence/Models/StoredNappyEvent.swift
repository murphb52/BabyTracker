import Foundation
import SwiftData

@Model
final class StoredNappyEvent {
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
    var typeRawValue: String = ""
    var intensityRawValue: String?
    var pooColorRawValue: String?
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
        typeRawValue: String,
        intensityRawValue: String?,
        pooColorRawValue: String?,
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
        self.typeRawValue = typeRawValue
        self.intensityRawValue = intensityRawValue
        self.pooColorRawValue = pooColorRawValue
        self.syncStateRawValue = syncStateRawValue
        self.lastSyncedAt = lastSyncedAt
        self.lastSyncErrorCode = lastSyncErrorCode
    }
}
