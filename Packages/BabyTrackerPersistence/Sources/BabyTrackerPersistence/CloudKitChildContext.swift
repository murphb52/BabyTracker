import CloudKit
import Foundation

public struct CloudKitChildContext: Equatable, Sendable {
    public let childID: UUID
    public let zoneID: CKRecordZone.ID
    public let shareRecordName: String?
    public let databaseScope: CKDatabase.Scope

    public init(
        childID: UUID,
        zoneID: CKRecordZone.ID,
        shareRecordName: String? = nil,
        databaseScope: CKDatabase.Scope
    ) {
        self.childID = childID
        self.zoneID = zoneID
        self.shareRecordName = shareRecordName
        self.databaseScope = databaseScope
    }
}
