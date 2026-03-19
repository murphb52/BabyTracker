import Foundation
import SwiftData

@Model
final class StoredUserIdentity {
    var id: UUID = UUID()
    var displayName: String = ""
    var createdAt: Date = Date()
    var cloudKitUserRecordName: String?
    var syncStateRawValue: String = ""
    var lastSyncedAt: Date?
    var lastSyncErrorCode: String?

    init(
        id: UUID,
        displayName: String,
        createdAt: Date,
        cloudKitUserRecordName: String?,
        syncStateRawValue: String = "",
        lastSyncedAt: Date? = nil,
        lastSyncErrorCode: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.createdAt = createdAt
        self.cloudKitUserRecordName = cloudKitUserRecordName
        self.syncStateRawValue = syncStateRawValue
        self.lastSyncedAt = lastSyncedAt
        self.lastSyncErrorCode = lastSyncErrorCode
    }
}
