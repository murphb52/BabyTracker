import CloudKit
import Foundation

public struct SyncAnchor: Equatable, Sendable {
    public let databaseScope: CKDatabase.Scope
    public let zoneID: CKRecordZone.ID?
    public let tokenData: Data?
    public let lastSyncAt: Date?

    public init(
        databaseScope: CKDatabase.Scope,
        zoneID: CKRecordZone.ID? = nil,
        tokenData: Data? = nil,
        lastSyncAt: Date? = nil
    ) {
        self.databaseScope = databaseScope
        self.zoneID = zoneID
        self.tokenData = tokenData
        self.lastSyncAt = lastSyncAt
    }
}
