import BabyTrackerDomain
import BabyTrackerPersistence
import CloudKit
import Foundation
import Testing

@MainActor
struct SyncStateRepositoryTests {
    @Test
    func reportsPendingRecordsAndFailureState() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let owner = try UserIdentity(displayName: "Alex Parent")
        let child = try Child(name: "Poppy", createdBy: owner.id)
        let event = try BottleFeedEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: Date(timeIntervalSince1970: 1_000),
                createdAt: Date(timeIntervalSince1970: 1_000),
                createdBy: owner.id
            ),
            amountMilliliters: 90
        )

        try harness.userIdentityRepository.saveLocalUser(owner)
        try harness.childRepository.saveChild(child)
        try harness.membershipRepository.saveMembership(
            .owner(
                childID: child.id,
                userID: owner.id,
                createdAt: child.createdAt
            )
        )
        try harness.eventRepository.saveEvent(.bottleFeed(event))

        let pendingRecords = try harness.syncRepository.loadPendingRecords()
        let eventRecord = try #require(
            pendingRecords.first(where: { $0.recordType == .bottleFeedEvent })
        )

        try harness.syncRepository.updateSyncState(
            for: eventRecord,
            state: .failed,
            lastSyncedAt: nil,
            lastSyncErrorCode: "network"
        )

        let summary = try harness.syncRepository.loadStatusSummary()

        #expect(pendingRecords.count == 4)
        #expect(summary.state == .failed)
        #expect(summary.pendingRecordCount == 3)
        #expect(summary.lastErrorDescription == "network")
    }

    @Test
    func savesAndLoadsZoneAnchors() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let zoneID = CKRecordZone.ID(zoneName: "child-123", ownerName: "owner")
        let anchor = SyncAnchor(
            databaseScope: .shared,
            zoneID: zoneID,
            tokenData: Data([0x01, 0x02, 0x03]),
            lastSyncAt: Date(timeIntervalSince1970: 2_000)
        )

        try harness.syncRepository.saveAnchor(anchor)

        let loadedAnchor = try #require(
            try harness.syncRepository.loadAnchor(
                databaseScope: "shared",
                zoneName: zoneID.zoneName,
                ownerName: zoneID.ownerName
            )
        )

        #expect(loadedAnchor.databaseScope == .shared)
        #expect(loadedAnchor.zoneID == zoneID)
        #expect(loadedAnchor.tokenData == anchor.tokenData)
        #expect(loadedAnchor.lastSyncAt == anchor.lastSyncAt)
    }
}

extension SyncStateRepositoryTests {
    @MainActor
    private struct RepositoryHarness {
        let childRepository: SwiftDataChildRepository
        let userIdentityRepository: SwiftDataUserIdentityRepository
        let membershipRepository: SwiftDataMembershipRepository
        let eventRepository: SwiftDataEventRepository
        let syncRepository: SwiftDataSyncStateRepository
        private let userDefaults: UserDefaults
        private let suiteName: String

        init() throws {
            let suiteName = "BabyTracker.SyncTests.\(UUID().uuidString)"
            let store = try BabyTrackerModelStore(isStoredInMemoryOnly: true)
            let userDefaults = UserDefaults(suiteName: suiteName)!
            userDefaults.removePersistentDomain(forName: suiteName)

            self.childRepository = SwiftDataChildRepository(store: store)
            self.userIdentityRepository = SwiftDataUserIdentityRepository(store: store, userDefaults: userDefaults)
            self.membershipRepository = SwiftDataMembershipRepository(store: store)
            self.eventRepository = SwiftDataEventRepository(store: store)
            self.syncRepository = SwiftDataSyncStateRepository(store: store)
            self.userDefaults = userDefaults
            self.suiteName = suiteName
        }

        func cleanUp() {
            userDefaults.removePersistentDomain(forName: suiteName)
        }
    }
}
