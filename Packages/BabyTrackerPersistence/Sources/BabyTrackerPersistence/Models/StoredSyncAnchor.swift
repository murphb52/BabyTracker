import Foundation
import SwiftData

@Model
final class StoredSyncAnchor {
    var databaseScope: String = ""
    var zoneName: String?
    var ownerName: String?
    var tokenData: Data?
    var lastSyncAt: Date?

    init(
        databaseScope: String,
        zoneName: String?,
        ownerName: String?,
        tokenData: Data?,
        lastSyncAt: Date?
    ) {
        self.databaseScope = databaseScope
        self.zoneName = zoneName
        self.ownerName = ownerName
        self.tokenData = tokenData
        self.lastSyncAt = lastSyncAt
    }
}
