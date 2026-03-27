import BabyTrackerDomain
import BabyTrackerPersistence
@testable import BabyTrackerSync
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

        let childRepository = SwiftDataChildRepository(store: store)
        let userIdentityRepository = SwiftDataUserIdentityRepository(store: store, userDefaults: userDefaults)
        let membershipRepository = SwiftDataMembershipRepository(store: store)
        let eventRepository = SwiftDataEventRepository(store: store)
        let syncStateRepository = SwiftDataSyncStateRepository(store: store)
        let client = CloudKitClientSpy()
        let syncEngine = CloudKitSyncEngine(
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
            eventRepository: eventRepository,
            syncStateRepository: syncStateRepository,
            client: client
        )

        let localUser = try UserIdentity(displayName: "Alex Parent")
        let child = try Child(name: "Poppy", createdBy: localUser.id)

        try userIdentityRepository.saveLocalUser(localUser)
        try childRepository.saveChild(child)
        try membershipRepository.saveMembership(
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
        #expect(await client.savedDatabaseSubscriptionIDs == [
            CloudKitSubscriptionIDs.databaseSubscriptionID(for: .private),
            CloudKitSubscriptionIDs.databaseSubscriptionID(for: .shared)
        ])
    }

    @Test
    func remoteNotificationRefreshDoesNotCreateDuplicateSubscriptions() async throws {
        let store = try BabyTrackerModelStore(isStoredInMemoryOnly: true)
        let userDefaults = UserDefaults(suiteName: "CloudKitSyncEngineTests.remoteNotificationRefreshSubscriptions")!
        userDefaults.removePersistentDomain(forName: "CloudKitSyncEngineTests.remoteNotificationRefreshSubscriptions")
        defer {
            userDefaults.removePersistentDomain(forName: "CloudKitSyncEngineTests.remoteNotificationRefreshSubscriptions")
        }

        let childRepository = SwiftDataChildRepository(store: store)
        let userIdentityRepository = SwiftDataUserIdentityRepository(store: store, userDefaults: userDefaults)
        let membershipRepository = SwiftDataMembershipRepository(store: store)
        let eventRepository = SwiftDataEventRepository(store: store)
        let syncStateRepository = SwiftDataSyncStateRepository(store: store)
        let client = CloudKitClientSpy()
        let syncEngine = CloudKitSyncEngine(
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
            eventRepository: eventRepository,
            syncStateRepository: syncStateRepository,
            client: client
        )

        let localUser = try UserIdentity(displayName: "Alex Parent")
        try userIdentityRepository.saveLocalUser(localUser)

        _ = await syncEngine.prepareForLaunch()
        _ = await syncEngine.refreshAfterRemoteNotification()

        #expect(await client.savedDatabaseSubscriptionIDs == [
            CloudKitSubscriptionIDs.databaseSubscriptionID(for: .private),
            CloudKitSubscriptionIDs.databaseSubscriptionID(for: .shared)
        ])
    }

    @Test
    func pullDoesNotOverwriteNewerLocalBottleFeedEvent() async throws {
        let store = try BabyTrackerModelStore(isStoredInMemoryOnly: true)
        let userDefaults = UserDefaults(suiteName: "CloudKitSyncEngineTests.pullDoesNotOverwriteNewerLocalBottleFeedEvent")!
        userDefaults.removePersistentDomain(forName: "CloudKitSyncEngineTests.pullDoesNotOverwriteNewerLocalBottleFeedEvent")
        defer {
            userDefaults.removePersistentDomain(forName: "CloudKitSyncEngineTests.pullDoesNotOverwriteNewerLocalBottleFeedEvent")
        }

        let childRepository = SwiftDataChildRepository(store: store)
        let userIdentityRepository = SwiftDataUserIdentityRepository(store: store, userDefaults: userDefaults)
        let membershipRepository = SwiftDataMembershipRepository(store: store)
        let eventRepository = SwiftDataEventRepository(store: store)
        let syncStateRepository = SwiftDataSyncStateRepository(store: store)
        let client = CloudKitClientSpy()
        let syncEngine = CloudKitSyncEngine(
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
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

        try userIdentityRepository.saveLocalUser(localUser)
        try childRepository.saveChild(child)
        try membershipRepository.saveMembership(membership)

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

    @Test
    func forcePullAcceptedSharePerformsFullSharedZoneFetchAndSavesRecordsLocally() async throws {
        let store = try BabyTrackerModelStore(isStoredInMemoryOnly: true)
        let userDefaults = UserDefaults(suiteName: "CloudKitSyncEngineTests.forcePullAcceptedShare")!
        userDefaults.removePersistentDomain(forName: "CloudKitSyncEngineTests.forcePullAcceptedShare")
        defer {
            userDefaults.removePersistentDomain(forName: "CloudKitSyncEngineTests.forcePullAcceptedShare")
        }

        let childRepository = SwiftDataChildRepository(store: store)
        let userIdentityRepository = SwiftDataUserIdentityRepository(store: store, userDefaults: userDefaults)
        let membershipRepository = SwiftDataMembershipRepository(store: store)
        let eventRepository = SwiftDataEventRepository(store: store)
        let syncStateRepository = SwiftDataSyncStateRepository(store: store)
        let client = CloudKitClientSpy()
        let syncEngine = CloudKitSyncEngine(
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
            eventRepository: eventRepository,
            syncStateRepository: syncStateRepository,
            client: client
        )

        let owner = try UserIdentity(displayName: "Sam Owner")
        let child = try Child(name: "Robin", createdBy: owner.id)
        let ownerMembership = Membership.owner(
            childID: child.id,
            userID: owner.id,
            createdAt: child.createdAt
        )
        let event = try BottleFeedEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: child.createdAt.addingTimeInterval(600),
                createdAt: child.createdAt.addingTimeInterval(600),
                createdBy: owner.id
            ),
            amountMilliliters: 150
        )

        let zoneID = CKRecordZone.ID(zoneName: "child-\(child.id.uuidString)", ownerName: "owner-record-name")
        let rootRecordID = CKRecord.ID(recordName: "child.\(child.id.uuidString)", zoneID: zoneID)

        try await client.modifyRecordZones(
            saving: [CKRecordZone(zoneID: zoneID)],
            deleting: [],
            databaseScope: .shared
        )
        _ = try await client.modifyRecords(
            saving: [
                CloudKitRecordMapper.childRecord(from: child, zoneID: zoneID),
                CloudKitRecordMapper.userRecord(from: owner, childID: child.id, zoneID: zoneID),
                CloudKitRecordMapper.membershipRecord(from: ownerMembership, zoneID: zoneID),
                CloudKitRecordMapper.eventRecord(from: .bottleFeed(event), zoneID: zoneID)
            ],
            deleting: [],
            databaseScope: .shared,
            savePolicy: .changedKeys
        )

        try await syncEngine.forcePullAcceptedShare(
            rootRecordID: rootRecordID,
            shareRecordName: "share.child.\(child.id.uuidString)"
        )

        let savedChild = try #require(try childRepository.loadChild(id: child.id))
        let savedOwner = try #require(try userIdentityRepository.loadUsers(for: [owner.id]).first)
        let savedMemberships = try membershipRepository.loadMemberships(for: child.id)
        let savedEvent = try #require(try eventRepository.loadEvent(id: event.id))
        let savedContext = try #require(try childRepository.loadCloudKitChildContext(id: child.id))

        #expect(savedChild.name == child.name)
        #expect(savedOwner.displayName == owner.displayName)
        #expect(savedMemberships.contains(where: { $0.id == ownerMembership.id }))
        #expect(savedContext.zoneID == zoneID)
        #expect(savedContext.databaseScope == .shared)
        switch savedEvent {
        case let .bottleFeed(feed):
            #expect(feed.amountMilliliters == 150)
        default:
            Issue.record("Expected a bottle feed event")
        }

        let zoneRequests = await client.zoneChangeRequests
        #expect(zoneRequests.contains(where: {
            $0.zoneID == zoneID &&
            $0.databaseScope == .shared &&
            $0.tokenWasNil
        }))
    }

    @Test
    func localWriteRefreshFullyReconcilesOwnerSharedPrivateZoneBeforePush() async throws {
        let store = try BabyTrackerModelStore(isStoredInMemoryOnly: true)
        let userDefaults = UserDefaults(suiteName: "CloudKitSyncEngineTests.ownerSharedPrivateZoneReconcile")!
        userDefaults.removePersistentDomain(forName: "CloudKitSyncEngineTests.ownerSharedPrivateZoneReconcile")
        defer {
            userDefaults.removePersistentDomain(forName: "CloudKitSyncEngineTests.ownerSharedPrivateZoneReconcile")
        }

        let childRepository = SwiftDataChildRepository(store: store)
        let userIdentityRepository = SwiftDataUserIdentityRepository(store: store, userDefaults: userDefaults)
        let membershipRepository = SwiftDataMembershipRepository(store: store)
        let eventRepository = SwiftDataEventRepository(store: store)
        let syncStateRepository = SwiftDataSyncStateRepository(store: store)
        let client = CloudKitClientSpy()
        let syncEngine = CloudKitSyncEngine(
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
            eventRepository: eventRepository,
            syncStateRepository: syncStateRepository,
            client: client
        )

        let owner = try UserIdentity(displayName: "Owner")
        let caregiver = try UserIdentity(displayName: "Caregiver")
        let child = try Child(name: "Test 3", createdBy: owner.id)
        let ownerMembership = Membership.owner(
            childID: child.id,
            userID: owner.id,
            createdAt: child.createdAt
        )
        let caregiverMembership = Membership(
            childID: child.id,
            userID: caregiver.id,
            role: .caregiver,
            status: .active,
            invitedAt: child.createdAt,
            acceptedAt: child.createdAt
        )
        let ownerEvent = try NappyEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: child.createdAt.addingTimeInterval(60),
                createdAt: child.createdAt.addingTimeInterval(60),
                createdBy: owner.id
            ),
            type: .mixed
        )
        let caregiverEvent = try BottleFeedEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: child.createdAt.addingTimeInterval(120),
                createdAt: child.createdAt.addingTimeInterval(120),
                createdBy: caregiver.id
            ),
            amountMilliliters: 90
        )

        let zoneID = CloudKitRecordNames.zoneID(for: child.id)
        let shareRecordID = CloudKitRecordNames.shareRecordID(
            childID: child.id,
            zoneID: zoneID
        )
        let childRecord = CloudKitRecordMapper.childRecord(from: child, zoneID: zoneID)
        let share = CKShare(
            rootRecord: childRecord,
            shareID: shareRecordID
        )

        try userIdentityRepository.saveLocalUser(owner)
        try userIdentityRepository.saveUser(caregiver)
        try childRepository.saveChild(child)
        try membershipRepository.saveCloudKitMembership(ownerMembership)
        try membershipRepository.saveCloudKitMembership(caregiverMembership)
        try eventRepository.saveEvent(.nappy(ownerEvent))
        try childRepository.saveCloudKitChildContext(
            CloudKitChildContext(
                childID: child.id,
                zoneID: zoneID,
                shareRecordName: shareRecordID.recordName,
                databaseScope: .private
            )
        )

        try syncStateRepository.updateSyncState(
            for: SyncRecordReference(recordType: .child, recordID: child.id, childID: child.id),
            state: .upToDate,
            lastSyncedAt: .now,
            lastSyncErrorCode: nil
        )
        try syncStateRepository.updateSyncState(
            for: SyncRecordReference(recordType: .membership, recordID: ownerMembership.id, childID: child.id),
            state: .upToDate,
            lastSyncedAt: .now,
            lastSyncErrorCode: nil
        )
        try syncStateRepository.updateSyncState(
            for: SyncRecordReference(recordType: .membership, recordID: caregiverMembership.id, childID: child.id),
            state: .upToDate,
            lastSyncedAt: .now,
            lastSyncErrorCode: nil
        )
        try syncStateRepository.updateSyncState(
            for: SyncRecordReference(recordType: .nappyEvent, recordID: ownerEvent.id, childID: child.id),
            state: .upToDate,
            lastSyncedAt: .now,
            lastSyncErrorCode: nil
        )

        try await client.modifyRecordZones(
            saving: [CKRecordZone(zoneID: zoneID)],
            deleting: [],
            databaseScope: .private
        )
        _ = try await client.modifyRecords(
            saving: [
                childRecord,
                share,
                CloudKitRecordMapper.userRecord(from: owner, childID: child.id, zoneID: zoneID),
                CloudKitRecordMapper.userRecord(from: caregiver, childID: child.id, zoneID: zoneID),
                CloudKitRecordMapper.membershipRecord(from: ownerMembership, zoneID: zoneID),
                CloudKitRecordMapper.membershipRecord(from: caregiverMembership, zoneID: zoneID),
                CloudKitRecordMapper.eventRecord(from: .nappy(ownerEvent), zoneID: zoneID),
                CloudKitRecordMapper.eventRecord(from: .bottleFeed(caregiverEvent), zoneID: zoneID)
            ],
            deleting: [],
            databaseScope: .private,
            savePolicy: .changedKeys
        )

        _ = await syncEngine.refreshAfterLocalWrite()

        let savedCaregiverEvent = try #require(try eventRepository.loadEvent(id: caregiverEvent.id))
        switch savedCaregiverEvent {
        case let .bottleFeed(event):
            #expect(event.amountMilliliters == 90)
        default:
            Issue.record("Expected caregiver bottle feed event")
        }

        let zoneRequests = await client.zoneChangeRequests
        #expect(zoneRequests.contains(where: {
            $0.zoneID == zoneID &&
            $0.databaseScope == .private &&
            $0.tokenWasNil
        }))
    }
}

private actor CloudKitClientSpy: CloudKitClient {
    nonisolated let container: CKContainer? = nil

    private(set) var existingZoneIDs: Set<CKRecordZone.ID> = []
    private(set) var createdZoneIDs: [CKRecordZone.ID] = []
    private(set) var queriedZoneIDs: [CKRecordZone.ID] = []
    private(set) var zoneChangeZoneIDs: [CKRecordZone.ID] = []
    private(set) var zoneChangeRequests: [(zoneID: CKRecordZone.ID, databaseScope: CKDatabase.Scope, tokenWasNil: Bool)] = []
    private(set) var savedDatabaseSubscriptionIDs: [String] = []
    private var databaseSubscriptionsByID: [String: CKSubscription] = [:]
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
        zoneChangeRequests.append((
            zoneID: zoneID,
            databaseScope: databaseScope,
            tokenWasNil: tokenData == nil
        ))

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

    func subscription(
        withID subscriptionID: String,
        databaseScope: CKDatabase.Scope
    ) async throws -> CKSubscription? {
        _ = databaseScope
        return databaseSubscriptionsByID[subscriptionID]
    }

    func saveSubscription(
        _ subscription: CKSubscription,
        databaseScope: CKDatabase.Scope
    ) async throws {
        _ = databaseScope
        databaseSubscriptionsByID[subscription.subscriptionID] = subscription
        savedDatabaseSubscriptionIDs.append(subscription.subscriptionID)
    }
}
