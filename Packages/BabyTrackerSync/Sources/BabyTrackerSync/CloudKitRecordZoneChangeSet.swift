import CloudKit
import Foundation

public struct CloudKitRecordZoneDeletion: Sendable {
    public let recordID: CKRecord.ID
    public let recordType: String

    public init(recordID: CKRecord.ID, recordType: String) {
        self.recordID = recordID
        self.recordType = recordType
    }
}

public struct CloudKitRecordZoneChangeSet: Sendable {
    public let modifiedRecords: [CKRecord]
    public let deletions: [CloudKitRecordZoneDeletion]
    public let tokenData: Data?

    public init(
        modifiedRecords: [CKRecord],
        deletions: [CloudKitRecordZoneDeletion],
        tokenData: Data?
    ) {
        self.modifiedRecords = modifiedRecords
        self.deletions = deletions
        self.tokenData = tokenData
    }
}
