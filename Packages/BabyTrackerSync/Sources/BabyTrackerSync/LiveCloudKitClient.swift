import CloudKit
import Foundation

public struct LiveCloudKitClient: CloudKitClient {
    public let container: CKContainer?

    public init(container: CKContainer = CloudKitConfiguration.container()) {
        self.container = container
    }

    public func accountStatus() async throws -> CKAccountStatus {
        try await resolvedContainer.accountStatus()
    }

    public func userRecordID() async throws -> CKRecord.ID {
        try await resolvedContainer.userRecordID()
    }

    public func recordZones(
        for ids: [CKRecordZone.ID],
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecordZone.ID: CKRecordZone] {
        let results = try await database(for: databaseScope).recordZones(for: ids)
        return results.compactMapValues { try? $0.get() }
    }

    public func modifyRecordZones(
        saving zones: [CKRecordZone],
        deleting zoneIDs: [CKRecordZone.ID],
        databaseScope: CKDatabase.Scope
    ) async throws {
        _ = try await database(for: databaseScope).modifyRecordZones(
            saving: zones,
            deleting: zoneIDs
        )
    }

    public func records(
        for ids: [CKRecord.ID],
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecord.ID: CKRecord] {
        let results = try await database(for: databaseScope).records(for: ids)
        return results.compactMapValues { try? $0.get() }
    }

    public func records(
        matching query: CKQuery,
        in zoneID: CKRecordZone.ID,
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecord] {
        var matchedRecords: [CKRecord] = []
        var currentCursor: CKQueryOperation.Cursor?

        repeat {
            if let cursor = currentCursor {
                let page = try await database(for: databaseScope).records(
                    continuingMatchFrom: cursor
                )
                matchedRecords.append(contentsOf: page.matchResults.compactMap { _, result in
                    try? result.get()
                })
                currentCursor = page.queryCursor
            } else {
                let page = try await database(for: databaseScope).records(
                    matching: query,
                    inZoneWith: zoneID
                )
                matchedRecords.append(contentsOf: page.matchResults.compactMap { _, result in
                    try? result.get()
                })
                currentCursor = page.queryCursor
            }
        } while currentCursor != nil

        return matchedRecords
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
        let result = try await database(for: databaseScope).modifyRecords(
            saving: records,
            deleting: recordIDs,
            savePolicy: savePolicy,
            atomically: true
        )

        return (
            saveResults: result.saveResults.mapValues { result in
                result.mapError { $0 }
            },
            deleteResults: result.deleteResults.mapValues { result in
                result.mapError { $0 }
            }
        )
    }

    public func databaseChanges(
        in databaseScope: CKDatabase.Scope,
        since tokenData: Data?
    ) async throws -> CloudKitDatabaseChangeSet {
        let token = try token(from: tokenData)
        let changes = try await database(for: databaseScope).databaseChanges(
            since: token
        )

        return CloudKitDatabaseChangeSet(
            modifiedZoneIDs: changes.modifications.map(\.zoneID),
            deletedZoneIDs: changes.deletions.map(\.zoneID),
            tokenData: try archive(token: changes.changeToken),
            moreComing: changes.moreComing
        )
    }

    public func recordZoneChanges(
        in zoneID: CKRecordZone.ID,
        databaseScope: CKDatabase.Scope,
        since tokenData: Data?
    ) async throws -> CloudKitRecordZoneChangeSet {
        var modifiedRecords: [CKRecord] = []
        var deletions: [CloudKitRecordZoneDeletion] = []
        var currentToken = try token(from: tokenData)
        var latestTokenData = tokenData

        while true {
            let changes = try await database(for: databaseScope).recordZoneChanges(
                inZoneWith: zoneID,
                since: currentToken
            )

            modifiedRecords.append(contentsOf: changes.modificationResultsByID.compactMap { _, result in
                try? result.get().record
            })
            deletions.append(contentsOf: changes.deletions.map { deletion in
                CloudKitRecordZoneDeletion(
                    recordID: deletion.recordID,
                    recordType: deletion.recordType
                )
            })
            latestTokenData = try archive(token: changes.changeToken)

            guard changes.moreComing else {
                break
            }

            currentToken = changes.changeToken
        }

        return CloudKitRecordZoneChangeSet(
            modifiedRecords: modifiedRecords,
            deletions: deletions,
            tokenData: latestTokenData
        )
    }

    public func accept(_ metadatas: [CKShare.Metadata]) async throws {
        _ = try await resolvedContainer.accept(metadatas)
    }

    public func subscription(
        withID subscriptionID: String,
        databaseScope: CKDatabase.Scope
    ) async throws -> CKSubscription? {
        do {
            return try await database(for: databaseScope).subscription(for: subscriptionID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    public func saveSubscription(
        _ subscription: CKSubscription,
        databaseScope: CKDatabase.Scope
    ) async throws {
        _ = try await database(for: databaseScope).modifySubscriptions(
            saving: [subscription],
            deleting: []
        )
    }

    private func database(for scope: CKDatabase.Scope) -> CKDatabase {
        resolvedContainer.database(with: scope)
    }

    private var resolvedContainer: CKContainer {
        guard let container else {
            preconditionFailure("LiveCloudKitClient requires a CKContainer.")
        }

        return container
    }

    private func token(from data: Data?) throws -> CKServerChangeToken? {
        guard let data else {
            return nil
        }

        return try NSKeyedUnarchiver.unarchivedObject(
            ofClass: CKServerChangeToken.self,
            from: data
        )
    }

    private func archive(token: CKServerChangeToken) throws -> Data {
        try NSKeyedArchiver.archivedData(
            withRootObject: token,
            requiringSecureCoding: true
        )
    }
}
