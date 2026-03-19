import Foundation
import SwiftData

@Model
final class StoredChild {
    var id: UUID = UUID()
    var name: String = ""
    var birthDate: Date?
    var createdAt: Date = Date()
    var createdBy: UUID = UUID()
    var isArchived: Bool = false
    var cloudKitZoneName: String?
    var cloudKitZoneOwnerName: String?
    var cloudKitShareRecordName: String?
    var cloudKitDatabaseScopeRawValue: String?
    var syncStateRawValue: String = ""
    var lastSyncedAt: Date?
    var lastSyncErrorCode: String?

    init(
        id: UUID,
        name: String,
        birthDate: Date?,
        createdAt: Date,
        createdBy: UUID,
        isArchived: Bool,
        cloudKitZoneName: String? = nil,
        cloudKitZoneOwnerName: String? = nil,
        cloudKitShareRecordName: String? = nil,
        cloudKitDatabaseScopeRawValue: String? = nil,
        syncStateRawValue: String = "",
        lastSyncedAt: Date? = nil,
        lastSyncErrorCode: String? = nil
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.isArchived = isArchived
        self.cloudKitZoneName = cloudKitZoneName
        self.cloudKitZoneOwnerName = cloudKitZoneOwnerName
        self.cloudKitShareRecordName = cloudKitShareRecordName
        self.cloudKitDatabaseScopeRawValue = cloudKitDatabaseScopeRawValue
        self.syncStateRawValue = syncStateRawValue
        self.lastSyncedAt = lastSyncedAt
        self.lastSyncErrorCode = lastSyncErrorCode
    }
}
