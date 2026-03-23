import BabyTrackerDomain
import BabyTrackerPersistence
import BabyTrackerSync
import CloudKit
import Foundation
import Testing

@MainActor
struct CloudKitSyncEngineTests {
    @Test
    func prepareForLaunchCreatesMissingPrivateZoneBeforeLoadingRecords() async throws {
        let store = try BabyTrackerModelStore(isStoredInMemoryOnly: true)
        let userDefaults = UserDefaults(suiteName: "CloudKitSyncEngineTests.prepareForLaunch")!
        userDefaults.removePersistentDomain(forName: "CloudKitSyncEngineTests.prepareForLaunch")
        defer {
            userDefaults.removePersistentDomain(forName: "CloudKitSyncEngineTests.prepareForLaunch")
        }

        let childRepository = SwiftDataChildProfileRepository(
            store: store,
            userDefaults: userDefaults
        )
        let eventRepository = SwiftDataEventRepository(store: store)
        let syncStateRepository = SwiftDataSyncStateRepository(store: store)
        let client = CloudKitClientSpy()
        let syncEngine = CloudKitSyncEngine(
            childRepository: childRepository,
            eventRepository: eventRepository,
            syncStateRepository: syncStateRepository,
            client: client
        )

        let localUser = try UserIdentity(displayName: "Alex Parent")
        let child = try Child(name: "Poppy", createdBy: localUser.id)

        try childRepository.saveLocalUser(localUser)
        try childRepository.saveChild(child)
        try childRepository.saveMembership(
            .owner(
                childID: child.id,
                userID: localUser.id,
                createdAt: child.createdAt
            )
        )

        let summary = await syncEngine.prepareForLaunch()
        let context = try childRepository.loadCloudKitChildContext(id: child.id)
        let expectedZoneID = CloudKitRecordNames.zoneID(for: child.id)

        #expect(summary.state == .upToDate)
        #expect(context?.zoneID == expectedZoneID)
        #expect(await client.createdZoneIDs == [expectedZoneID])
        #expect(!(await client.queriedZoneIDs.contains(expectedZoneID)))
    }

    @Test
    func pullDoesNotOverwriteNewerLocalBottleFeedEvent() async throws {
        let store = try BabyTrackerModelStore(isStoredInMemoryOnly: true)
        let userDefaults = UserDefaults(suiteName: "CloudKitSyncEngineTests.pullDoesNotOverwriteNewerLocalBottleFeedEvent")!
        userDefaults.removePersistentDomain(forName: "CloudKitSyncEngineTests.pullDoesNotOverwriteNewerLocalBottleFeedEvent")
        defer {
            userDefaults.removePersistentDomain(forName: "CloudKitSyncEngineTests.pullDoesNotOverwriteNewerLocalBottleFeedEvent")
        }

        let childRepository = SwiftDataChildProfileRepository(
            store: store,
            userDefaults: userDefaults
        )
        let eventRepository = SwiftDataEventRepository(store: store)
        let syncStateRepository = SwiftDataSyncStateRepository(store: store)
        let client = CloudKitClientSpy()
        let syncEngine = CloudKitSyncEngine(
            childRepository: childRepository,
            eventRepository: eventRepository,
            syncStateRepository: syncStateRepository,
            client: client
        )

        let localUser = try UserIdentity(displayName: "Alex Parent")
        let child = try Child(name: "Poppy", createdBy: localUser.id)
        let membership = Membership.owner(
            childID: child.id,
            userID: localUser.id,
            createdAt: child.createdAt
        )

        try childRepository.saveLocalUser(localUser)
        try childRepository.saveChild(child)
        try childRepository.saveMembership(membership)

        // Ensure `pullKnownChildZones()` pulls (not pushes) by pre-saving the CloudKit context.
        let zoneID = CloudKitRecordNames.zoneID(for: child.id)
        let context = CloudKitChildContext(
            childID: child.id,
            zoneID: zoneID,
            databaseScope: .private
        )
        try childRepository.saveCloudKitChildContext(context)

        // Seed the spy with a known zone so `recordZoneChanges` succeeds.
        try await client.modifyRecordZones(
            saving: [CKRecordZone(zoneID: zoneID)],
            deleting: [],
            databaseScope: .private
        )

        let eventID = UUID()
        let localOccurredAt = Date(timeIntervalSince1970: 9_000)
        let remoteOccurredAt = Date(timeIntervalSince1970: 9_000 + 2_400)
        let localUpdatedAt = Date(timeIntervalSince1970: 10_000)
        let remoteUpdatedAt = Date(timeIntervalSince1970: 9_500)
        let remoteUpdatedBy = UUID()

        let localEvent = try BottleFeedEvent(
            metadata: EventMetadata(
                id: eventID,
                childID: child.id,
                occurredAt: localOccurredAt,
                createdAt: localOccurredAt,
                createdBy: localUser.id,
                updatedAt: localUpdatedAt,
                updatedBy: localUser.id
            ),
            amountMilliliters: 120
        )

        try eventRepository.saveEvent(.bottleFeed(localEvent))

        // Only the edited event should be pending; all other sync states should appear up-to-date.
        try syncStateRepository.updateSyncState(
            for: SyncRecordReference(recordType: .child, recordID: child.id, childID: child.id),
            state: .upToDate,
            lastSyncedAt: .now,
            lastSyncErrorCode: nil
        )
        try syncStateRepository.updateSyncState(
            for: SyncRecordReference(recordType: .user, recordID: localUser.id),
            state: .upToDate,
            lastSyncedAt: .now,
            lastSyncErrorCode: nil
        )
        try syncStateRepository.updateSyncState(
            for: SyncRecordReference(recordType: .membership, recordID: membership.id, childID: membership.childID),
            state: .upToDate,
            lastSyncedAt: .now,
            lastSyncErrorCode: nil
        )

        #expect(
            (try syncStateRepository.loadPendingRecords()).contains(where: { $0.recordType == .bottleFeedEvent })
        )

        let remoteEvent = try BottleFeedEvent(
            metadata: EventMetadata(
                id: eventID,
                childID: child.id,
                occurredAt: remoteOccurredAt,
                createdAt: remoteOccurredAt,
                createdBy: localUser.id,
                updatedAt: remoteUpdatedAt,
                updatedBy: remoteUpdatedBy
            ),
            amountMilliliters: 120
        )

        let remoteRecord = CloudKitRecordMapper.eventRecord(
            from: .bottleFeed(remoteEvent),
            zoneID: zoneID
        )
        _ = try await client.modifyRecords(
            saving: [remoteRecord],
            deleting: [],
            databaseScope: .private,
            savePolicy: .changedKeys
        )

        _ = await syncEngine.refreshAfterLocalWrite()

        let reloadedEvent = try #require(try eventRepository.loadEvent(id: eventID))
        switch reloadedEvent {
        case let .bottleFeed(feed):
            #expect(feed.metadata.occurredAt == localOccurredAt)
        default:
            Issue.record("Expected a bottle feed event")
        }

        let pendingAfterRefresh = try syncStateRepository.loadPendingRecords()
        #expect(!pendingAfterRefresh.contains { $0.recordType == .bottleFeedEvent })
    }
}

private actor CloudKitClientSpy: CloudKitClient {
    nonisolated let container: CKContainer? = nil

    private(set) var existingZoneIDs: Set<CKRecordZone.ID> = []
    private(set) var createdZoneIDs: [CKRecordZone.ID] = []
    private(set) var queriedZoneIDs: [CKRecordZone.ID] = []
    private(set) var zoneChangeZoneIDs: [CKRecordZone.ID] = []
    private var recordsByID: [CKRecord.ID: CKRecord] = [:]
    private var knownRecordTypesByZoneID: [CKRecordZone.ID: Set<String>] = [:]

    func accountStatus() async throws -> CKAccountStatus {
        .available
    }

    func userRecordID() async throws -> CKRecord.ID {
        CKRecord.ID(recordName: "test-user-record")
    }

    func recordZones(
        for ids: [CKRecordZone.ID],
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecordZone.ID: CKRecordZone] {
        Dictionary(
            uniqueKeysWithValues: ids.compactMap { id in
                guard existingZoneIDs.contains(id) else {
                    return nil
                }

                return (id, CKRecordZone(zoneID: id))
            }
        )
    }

    func modifyRecordZones(
        saving zones: [CKRecordZone],
        deleting zoneIDs: [CKRecordZone.ID],
        databaseScope: CKDatabase.Scope
    ) async throws {
        for zone in zones {
            existingZoneIDs.insert(zone.zoneID)
            createdZoneIDs.append(zone.zoneID)
        }

        for zoneID in zoneIDs {
            existingZoneIDs.remove(zoneID)
        }
    }

    func records(
        for ids: [CKRecord.ID],
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecord.ID: CKRecord] {
        Dictionary(
            uniqueKeysWithValues: ids.compactMap { id in
                guard let record = recordsByID[id] else {
                    return nil
                }

                return (id, record)
            }
        )
    }

    func records(
        matching query: CKQuery,
        in zoneID: CKRecordZone.ID,
        databaseScope: CKDatabase.Scope
    ) async throws -> [CKRecord] {
        queriedZoneIDs.append(zoneID)

        guard existingZoneIDs.contains(zoneID) else {
            throw CKError(.zoneNotFound)
        }

        guard knownRecordTypesByZoneID[zoneID, default: []].contains(query.recordType) else {
            throw CKError(
                .unknownItem,
                userInfo: [NSLocalizedDescriptionKey: "Did not find record type: \(query.recordType)"]
            )
        }

        return recordsByID.values.filter { record in
            record.recordType == query.recordType && record.recordID.zoneID == zoneID
        }
    }

    func modifyRecords(
        saving records: [CKRecord],
        deleting recordIDs: [CKRecord.ID],
        databaseScope: CKDatabase.Scope,
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy
    ) async throws -> (
        saveResults: [CKRecord.ID: Result<CKRecord, Error>],
        deleteResults: [CKRecord.ID: Result<Void, Error>]
    ) {
        for record in records {
            recordsByID[record.recordID] = record
            knownRecordTypesByZoneID[record.recordID.zoneID, default: []].insert(record.recordType)
        }

        for recordID in recordIDs {
            recordsByID.removeValue(forKey: recordID)
        }

        return (
            saveResults: Dictionary(
                uniqueKeysWithValues: records.map { record in
                    (record.recordID, .success(record))
                }
            ),
            deleteResults: Dictionary(
                uniqueKeysWithValues: recordIDs.map { recordID in
                    (recordID, .success(()))
                }
            )
        )
    }

    func databaseChanges(
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

    func recordZoneChanges(
        in zoneID: CKRecordZone.ID,
        databaseScope: CKDatabase.Scope,
        since tokenData: Data?
    ) async throws -> CloudKitRecordZoneChangeSet {
        zoneChangeZoneIDs.append(zoneID)

        guard existingZoneIDs.contains(zoneID) else {
            throw CKError(.zoneNotFound)
        }

        return CloudKitRecordZoneChangeSet(
            modifiedRecords: recordsByID.values.filter { $0.recordID.zoneID == zoneID },
            deletions: [],
            tokenData: nil
        )
    }

    func accept(_ metadatas: [CKShare.Metadata]) async throws {}
}
