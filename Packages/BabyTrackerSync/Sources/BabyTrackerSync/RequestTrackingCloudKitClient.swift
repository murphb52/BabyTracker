import CloudKit
import Foundation

/// Wraps a `CloudKitClient` and reports each request's start and finish to a
/// `CloudKitRequestTracker`, so the sync engine can cancel a refresh pass
/// whose current request has hung.
struct RequestTrackingCloudKitClient: CloudKitClient {
    let wrapped: CloudKitClient
    let tracker: CloudKitRequestTracker

    var container: CKContainer? {
        wrapped.container
    }

    func accountStatus() async throws -> CKAccountStatus {
        let requestID = tracker.requestStarted()
        defer { tracker.requestFinished(requestID) }
        return try await wrapped.accountStatus()
    }

    func userRecordID() async throws -> CKRecord.ID {
        let requestID = tracker.requestStarted()
        defer { tracker.requestFinished(requestID) }
        return try await wrapped.userRecordID()
    }

    func recordZones(
        for ids: [CKRecordZone.ID],
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecordZone.ID: CKRecordZone] {
        let requestID = tracker.requestStarted()
        defer { tracker.requestFinished(requestID) }
        return try await wrapped.recordZones(for: ids, databaseScope: databaseScope)
    }

    func modifyRecordZones(
        saving zones: [CKRecordZone],
        deleting zoneIDs: [CKRecordZone.ID],
        databaseScope: CKDatabase.Scope
    ) async throws {
        let requestID = tracker.requestStarted()
        defer { tracker.requestFinished(requestID) }
        try await wrapped.modifyRecordZones(saving: zones, deleting: zoneIDs, databaseScope: databaseScope)
    }

    func records(
        for ids: [CKRecord.ID],
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecord.ID: CKRecord] {
        let requestID = tracker.requestStarted()
        defer { tracker.requestFinished(requestID) }
        return try await wrapped.records(for: ids, databaseScope: databaseScope)
    }

    func records(
        matching query: CKQuery,
        in zoneID: CKRecordZone.ID,
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecord] {
        let requestID = tracker.requestStarted()
        defer { tracker.requestFinished(requestID) }
        return try await wrapped.records(matching: query, in: zoneID, databaseScope: databaseScope)
    }

    func modifyRecords(
        saving records: [CKRecord],
        deleting recordIDs: [CKRecord.ID],
        databaseScope: CKDatabase.Scope,
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy,
        atomically: Bool
    ) async throws -> (
        saveResults: [CKRecord.ID: Result<CKRecord, Error>],
        deleteResults: [CKRecord.ID: Result<Void, Error>]
    ) {
        let requestID = tracker.requestStarted()
        defer { tracker.requestFinished(requestID) }
        return try await wrapped.modifyRecords(
            saving: records,
            deleting: recordIDs,
            databaseScope: databaseScope,
            savePolicy: savePolicy,
            atomically: atomically
        )
    }

    func databaseChanges(
        in databaseScope: CKDatabase.Scope,
        since tokenData: Data?
    ) async throws -> CloudKitDatabaseChangeSet {
        let requestID = tracker.requestStarted()
        defer { tracker.requestFinished(requestID) }
        return try await wrapped.databaseChanges(in: databaseScope, since: tokenData)
    }

    func recordZoneChanges(
        in zoneID: CKRecordZone.ID,
        databaseScope: CKDatabase.Scope,
        since tokenData: Data?
    ) async throws -> CloudKitRecordZoneChangeSet {
        let requestID = tracker.requestStarted()
        defer { tracker.requestFinished(requestID) }
        return try await wrapped.recordZoneChanges(in: zoneID, databaseScope: databaseScope, since: tokenData)
    }

    func accept(_ metadatas: [CKShare.Metadata]) async throws {
        let requestID = tracker.requestStarted()
        defer { tracker.requestFinished(requestID) }
        try await wrapped.accept(metadatas)
    }

    func subscription(
        withID subscriptionID: String,
        databaseScope: CKDatabase.Scope
    ) async throws -> CKSubscription? {
        let requestID = tracker.requestStarted()
        defer { tracker.requestFinished(requestID) }
        return try await wrapped.subscription(withID: subscriptionID, databaseScope: databaseScope)
    }

    func saveSubscription(
        _ subscription: CKSubscription,
        databaseScope: CKDatabase.Scope
    ) async throws {
        let requestID = tracker.requestStarted()
        defer { tracker.requestFinished(requestID) }
        try await wrapped.saveSubscription(subscription, databaseScope: databaseScope)
    }
}
