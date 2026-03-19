import BabyTrackerDomain
import BabyTrackerFeature
import BabyTrackerPersistence
import BabyTrackerSync
import Foundation
import Testing

@MainActor
struct AppModelTests {
    @Test
    func profileDerivesRecentFeedRowsInNewestFirstOrder() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let earlierFeed = try harness.saveBreastFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            start: Date(timeIntervalSince1970: 1_000),
            end: Date(timeIntervalSince1970: 1_600),
            side: .left
        )
        let laterFeed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 150,
            occurredAt: Date(timeIntervalSince1970: 2_000),
            milkType: .formula
        )

        harness.model.load(performLaunchSync: false)

        let profile = try #require(harness.model.profile)

        #expect(profile.recentFeedEvents.count == 2)
        #expect(profile.recentFeedEvents.map(\.id) == [laterFeed.id, earlierFeed.id])
        #expect(profile.recentFeedEvents.first?.detailText == "150 mL • Formula")
    }

    @Test
    func activeCaregiverCanEditAndDeleteFeedEvents() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedActiveCaregiverProfile()
        let feed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.owner.id,
            amountMilliliters: 120,
            occurredAt: Date(timeIntervalSince1970: 3_000),
            milkType: nil
        )

        harness.model.load(performLaunchSync: false)

        let profile = try #require(harness.model.profile)
        #expect(profile.canManageFeedEvents)

        #expect(
            harness.model.updateBottleFeed(
                id: feed.id,
                amountMilliliters: 180,
                occurredAt: Date(timeIntervalSince1970: 3_600),
                milkType: .formula
            )
        )

        let updatedEvent = try #require(try harness.eventRepository.loadEvent(id: feed.id))
        switch updatedEvent {
        case let .bottleFeed(event):
            #expect(event.amountMilliliters == 180)
            #expect(event.milkType == .formula)
        default:
            Issue.record("Expected an updated bottle feed")
        }

        #expect(harness.model.deleteEvent(id: feed.id))

        let visibleTimeline = try harness.eventRepository.loadTimeline(
            for: seed.child.id,
            includingDeleted: false
        )
        #expect(visibleTimeline.isEmpty)
        #expect(harness.model.undoDeleteMessage == "Bottle Feed deleted")
    }

    @Test
    func undoRestoresDeletedFeedAndClearsBannerState() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let feed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 120,
            occurredAt: Date(timeIntervalSince1970: 4_000),
            milkType: nil
        )

        harness.model.load(performLaunchSync: false)

        #expect(harness.model.deleteEvent(id: feed.id))
        harness.model.undoLastDeletedEvent()

        let visibleTimeline = try harness.eventRepository.loadTimeline(
            for: seed.child.id,
            includingDeleted: false
        )
        #expect(visibleTimeline.count == 1)
        #expect(visibleTimeline.first?.id == feed.id)
        #expect(harness.model.undoDeleteMessage == nil)
    }

    @Test
    func secondDeleteReplacesFirstUndoTarget() throws {
        let harness = try Harness()
        defer { harness.cleanUp() }

        let seed = try harness.seedOwnerProfile()
        let firstFeed = try harness.saveBottleFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            amountMilliliters: 120,
            occurredAt: Date(timeIntervalSince1970: 5_000),
            milkType: nil
        )
        let secondFeed = try harness.saveBreastFeed(
            childID: seed.child.id,
            userID: seed.localUser.id,
            start: Date(timeIntervalSince1970: 5_400),
            end: Date(timeIntervalSince1970: 5_700),
            side: .right
        )

        harness.model.load(performLaunchSync: false)

        #expect(harness.model.deleteEvent(id: firstFeed.id))
        #expect(harness.model.deleteEvent(id: secondFeed.id))

        harness.model.undoLastDeletedEvent()

        let visibleTimeline = try harness.eventRepository.loadTimeline(
            for: seed.child.id,
            includingDeleted: false
        )
        #expect(visibleTimeline.count == 1)
        #expect(visibleTimeline.first?.id == secondFeed.id)
        #expect(!visibleTimeline.contains(where: { $0.id == firstFeed.id }))
    }
}

extension AppModelTests {
    @MainActor
    private struct Harness {
        let suiteName = "BabyTrackerAppModelTests.\(UUID().uuidString)"
        let userDefaults: UserDefaults
        let store: BabyTrackerModelStore
        let childRepository: SwiftDataChildProfileRepository
        let eventRepository: SwiftDataEventRepository
        let syncStateRepository: SwiftDataSyncStateRepository
        let syncEngine: CloudKitSyncEngine
        let model: AppModel

        init() throws {
            let userDefaults = UserDefaults(suiteName: suiteName)!
            userDefaults.removePersistentDomain(forName: suiteName)

            self.userDefaults = userDefaults
            self.store = try BabyTrackerModelStore(isStoredInMemoryOnly: true)
            self.childRepository = SwiftDataChildProfileRepository(
                store: store,
                userDefaults: userDefaults
            )
            self.eventRepository = SwiftDataEventRepository(store: store)
            self.syncStateRepository = SwiftDataSyncStateRepository(store: store)
            self.syncEngine = CloudKitSyncEngine(
                childRepository: childRepository,
                eventRepository: eventRepository,
                syncStateRepository: syncStateRepository,
                client: UnavailableCloudKitClient()
            )
            self.model = AppModel(
                repository: childRepository,
                eventRepository: eventRepository,
                syncEngine: syncEngine
            )
        }

        func cleanUp() {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        func seedOwnerProfile() throws -> OwnerSeed {
            let owner = try UserIdentity(displayName: "Alex Parent")
            let child = try Child(name: "Poppy", createdBy: owner.id)

            try childRepository.saveLocalUser(owner)
            try childRepository.saveChild(child)
            try childRepository.saveMembership(
                .owner(
                    childID: child.id,
                    userID: owner.id,
                    createdAt: child.createdAt
                )
            )
            childRepository.saveSelectedChildID(child.id)

            return OwnerSeed(localUser: owner, child: child)
        }

        func seedActiveCaregiverProfile() throws -> ActiveCaregiverSeed {
            let owner = try UserIdentity(displayName: "Sam Owner")
            let caregiver = try UserIdentity(displayName: "Jamie Caregiver")
            let child = try Child(name: "Robin", createdBy: owner.id)

            try childRepository.saveUser(owner)
            try childRepository.saveLocalUser(caregiver)
            try childRepository.saveUser(caregiver)
            try childRepository.saveChild(child)
            try childRepository.saveMembership(
                .owner(
                    childID: child.id,
                    userID: owner.id,
                    createdAt: child.createdAt
                )
            )
            try childRepository.saveMembership(
                Membership(
                    childID: child.id,
                    userID: caregiver.id,
                    role: .caregiver,
                    status: .active,
                    invitedAt: child.createdAt,
                    acceptedAt: child.createdAt
                )
            )
            childRepository.saveSelectedChildID(child.id)

            return ActiveCaregiverSeed(
                owner: owner,
                localUser: caregiver,
                child: child
            )
        }

        func saveBreastFeed(
            childID: UUID,
            userID: UUID,
            start: Date,
            end: Date,
            side: BreastSide?
        ) throws -> BreastFeedEvent {
            let event = try BreastFeedEvent(
                metadata: EventMetadata(
                    childID: childID,
                    occurredAt: end,
                    createdAt: end,
                    createdBy: userID
                ),
                side: side,
                startedAt: start,
                endedAt: end
            )
            try eventRepository.saveEvent(.breastFeed(event))
            return event
        }

        func saveBottleFeed(
            childID: UUID,
            userID: UUID,
            amountMilliliters: Int,
            occurredAt: Date,
            milkType: MilkType?
        ) throws -> BottleFeedEvent {
            let event = try BottleFeedEvent(
                metadata: EventMetadata(
                    childID: childID,
                    occurredAt: occurredAt,
                    createdAt: occurredAt,
                    createdBy: userID
                ),
                amountMilliliters: amountMilliliters,
                milkType: milkType
            )
            try eventRepository.saveEvent(.bottleFeed(event))
            return event
        }
    }

    private struct OwnerSeed {
        let localUser: UserIdentity
        let child: Child
    }

    private struct ActiveCaregiverSeed {
        let owner: UserIdentity
        let localUser: UserIdentity
        let child: Child
    }
}
