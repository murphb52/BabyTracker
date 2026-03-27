import CloudKit
import Foundation

public struct UnavailableCloudKitClient: CloudKitClient {
    public let container: CKContainer? = nil

    public init() {}

    public func accountStatus() async throws -> CKAccountStatus {
        .noAccount
    }

    public func userRecordID() async throws -> CKRecord.ID {
        throw CKError(.notAuthenticated)
    }

    public func recordZones(
        for ids: [CKRecordZone.ID],
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecordZone.ID: CKRecordZone] {
        [:]
    }

    public func modifyRecordZones(
        saving zones: [CKRecordZone],
        deleting zoneIDs: [CKRecordZone.ID],
        databaseScope: CKDatabase.Scope
    ) async throws {
        throw CKError(.notAuthenticated)
    }

    public func records(
        for ids: [CKRecord.ID],
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecord.ID: CKRecord] {
        [:]
    }

    public func records(
        matching query: CKQuery,
        in zoneID: CKRecordZone.ID,
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecord] {
        []
    }

    public func modifyRecords(
        saving records: [CKRecord],
        deleting recordIDs: [CKRecord.ID],
        databaseScope: CKDatabase.Scope,
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy
    ) async throws -> (
        saveResults: [CKRecord.ID: Result<CKRecord, Error>],
        deleteResults: [CKRecord.ID: Result<Void, Error>]
    ) {
        throw CKError(.notAuthenticated)
    }

    public func databaseChanges(
        in databaseScope: CKDatabase.Scope,
        since tokenData: Data?
    ) async throws -> CloudKitDatabaseChangeSet {
        CloudKitDatabaseChangeSet(
            modifiedZoneIDs: [],
            deletedZoneIDs: [],
            tokenData: nil,
            moreComing: false
        )
    }

    public func recordZoneChanges(
        in zoneID: CKRecordZone.ID,
        databaseScope: CKDatabase.Scope,
        since tokenData: Data?
    ) async throws -> CloudKitRecordZoneChangeSet {
        CloudKitRecordZoneChangeSet(
            modifiedRecords: [],
            deletions: [],
            tokenData: nil
        )
    }

    public func accept(_ metadatas: [CKShare.Metadata]) async throws {
        throw CKError(.notAuthenticated)
    }

    public func subscription(
        withID subscriptionID: String,
        databaseScope: CKDatabase.Scope
    ) async throws -> CKSubscription? {
        nil
    }

    public func saveSubscription(
        _ subscription: CKSubscription,
        databaseScope: CKDatabase.Scope
    ) async throws {
        throw CKError(.notAuthenticated)
    }
}
