import CloudKit
import Foundation

public protocol CloudKitClient: Sendable {
    var container: CKContainer? { get }

    func accountStatus() async throws -> CKAccountStatus
    func userRecordID() async throws -> CKRecord.ID
    func recordZones(
        for ids: [CKRecordZone.ID],
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecordZone.ID: CKRecordZone]
    func modifyRecordZones(
        saving zones: [CKRecordZone],
        deleting zoneIDs: [CKRecordZone.ID],
        databaseScope: CKDatabase.Scope
    ) async throws
    func records(
        for ids: [CKRecord.ID],
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecord.ID: CKRecord]
    func records(
        matching query: CKQuery,
        in zoneID: CKRecordZone.ID,
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecord]
    func modifyRecords(
        saving records: [CKRecord],
        deleting recordIDs: [CKRecord.ID],
        databaseScope: CKDatabase.Scope,
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy
    ) async throws -> (
        saveResults: [CKRecord.ID: Result<CKRecord, Error>],
        deleteResults: [CKRecord.ID: Result<Void, Error>]
    )
    func databaseChanges(
        in databaseScope: CKDatabase.Scope,
        since tokenData: Data?
    ) async throws -> CloudKitDatabaseChangeSet
    func accept(_ metadatas: [CKShare.Metadata]) async throws
}
