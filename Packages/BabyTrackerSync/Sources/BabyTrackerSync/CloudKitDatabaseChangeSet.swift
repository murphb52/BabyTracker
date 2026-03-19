import CloudKit
import Foundation

public struct CloudKitDatabaseChangeSet: Sendable {
    public let modifiedZoneIDs: [CKRecordZone.ID]
    public let deletedZoneIDs: [CKRecordZone.ID]
    public let tokenData: Data?
    public let moreComing: Bool

    public init(
        modifiedZoneIDs: [CKRecordZone.ID],
        deletedZoneIDs: [CKRecordZone.ID],
        tokenData: Data?,
        moreComing: Bool
    ) {
        self.modifiedZoneIDs = modifiedZoneIDs
        self.deletedZoneIDs = deletedZoneIDs
        self.tokenData = tokenData
        self.moreComing = moreComing
    }
}
