import Foundation
import SwiftData

@Model
final class StoredMembership {
    var id: UUID = UUID()
    var childID: UUID = UUID()
    var userID: UUID = UUID()
    var roleRawValue: String = ""
    var statusRawValue: String = ""
    var invitedAt: Date = Date()
    var acceptedAt: Date?
    var syncStateRawValue: String = ""
    var lastSyncedAt: Date?
    var lastSyncErrorCode: String?

    init(
        id: UUID,
        childID: UUID,
        userID: UUID,
        roleRawValue: String,
        statusRawValue: String,
        invitedAt: Date,
        acceptedAt: Date?,
        syncStateRawValue: String = "",
        lastSyncedAt: Date? = nil,
        lastSyncErrorCode: String? = nil
    ) {
        self.id = id
        self.childID = childID
        self.userID = userID
        self.roleRawValue = roleRawValue
        self.statusRawValue = statusRawValue
        self.invitedAt = invitedAt
        self.acceptedAt = acceptedAt
        self.syncStateRawValue = syncStateRawValue
        self.lastSyncedAt = lastSyncedAt
        self.lastSyncErrorCode = lastSyncErrorCode
    }
}
