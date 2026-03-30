import CloudKit
import Foundation

@MainActor
public protocol CloudKitRecordMetadataRepository: AnyObject {
    func loadSystemFields(
        for recordID: CKRecord.ID,
        databaseScope: CKDatabase.Scope
    ) throws -> Data?
    func saveSystemFields(
        _ systemFieldsData: Data,
        for recordID: CKRecord.ID,
        databaseScope: CKDatabase.Scope
    ) throws
    func deleteSystemFields(
        for recordID: CKRecord.ID,
        databaseScope: CKDatabase.Scope
    ) throws
}
