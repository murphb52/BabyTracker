import Foundation
import SwiftData

@Model
final class StoredCloudKitRecordMetadata {
    var storageKey: String = ""
    var recordName: String = ""
    var zoneName: String = ""
    var ownerName: String = ""
    var databaseScopeRawValue: String = ""
    var systemFieldsData: Data = Data()

    init(
        storageKey: String,
        recordName: String,
        zoneName: String,
        ownerName: String,
        databaseScopeRawValue: String,
        systemFieldsData: Data
    ) {
        self.storageKey = storageKey
        self.recordName = recordName
        self.zoneName = zoneName
        self.ownerName = ownerName
        self.databaseScopeRawValue = databaseScopeRawValue
        self.systemFieldsData = systemFieldsData
    }
}
