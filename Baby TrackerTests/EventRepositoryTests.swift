import BabyTrackerDomain
import BabyTrackerPersistence
import Foundation
import Testing

@MainActor
struct EventRepositoryTests {
    @Test
    func savesEventsLoadsTimelineAndSupportsSoftDelete() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let childID = UUID()
        let userID = UUID()
        let morning = Date(timeIntervalSince1970: 1_000)
        let napStart = Date(timeIntervalSince1970: 2_000)
        let napEnd = Date(timeIntervalSince1970: 2_600)
        let feedTime = Date(timeIntervalSince1970: 3_000)

        let sleepEvent = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: napStart,
                createdAt: napStart,
                createdBy: userID
            ),
            startedAt: napStart,
            endedAt: napEnd
        )
        let bottleEvent = try BottleFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: feedTime,
                createdAt: feedTime,
                createdBy: userID,
                notes: "  Bedtime feed  "
            ),
            amountMilliliters: 120
        )

        try harness.repository.saveEvent(.sleep(sleepEvent))
        try harness.repository.saveEvent(.bottleFeed(bottleEvent))

        let timeline = try harness.repository.loadTimeline(for: childID, includingDeleted: false)
        let dayEvents = try harness.repository.loadEvents(
            for: childID,
            on: morning,
            calendar: Calendar(identifier: .gregorian),
            includingDeleted: false
        )
        let reloadedBottleEvent = try #require(
            try harness.repository.loadEvent(id: bottleEvent.id)
        )

        #expect(timeline.map(\.kind) == [.bottleFeed, .sleep])
        #expect(dayEvents.map(\.kind) == [.bottleFeed, .sleep])

        switch reloadedBottleEvent {
        case let .bottleFeed(event):
            #expect(event.amountMilliliters == 120)
            #expect(event.milkType == nil)
            #expect(event.metadata.notes == "Bedtime feed")
        default:
            Issue.record("Expected a bottle feed event")
        }

        try harness.repository.softDeleteEvent(
            id: bottleEvent.id,
            deletedAt: feedTime.addingTimeInterval(60),
            deletedBy: userID
        )

        let visibleTimeline = try harness.repository.loadTimeline(for: childID, includingDeleted: false)
        let deletedTimeline = try harness.repository.loadTimeline(for: childID, includingDeleted: true)

        #expect(visibleTimeline.map(\.kind) == [.sleep])
        #expect(deletedTimeline.count == 2)
        #expect(deletedTimeline.contains(where: { $0.id == bottleEvent.id && $0.metadata.isDeleted }))
    }

    @Test
    func loadsActiveSleepEventForOpenSleepSession() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let childID = UUID()
        let userID = UUID()
        let earlierSleep = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: Date(timeIntervalSince1970: 1_000),
                createdAt: Date(timeIntervalSince1970: 1_000),
                createdBy: userID
            ),
            startedAt: Date(timeIntervalSince1970: 1_000),
            endedAt: Date(timeIntervalSince1970: 1_200)
        )
        let activeSleep = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: Date(timeIntervalSince1970: 2_000),
                createdAt: Date(timeIntervalSince1970: 2_000),
                createdBy: userID
            ),
            startedAt: Date(timeIntervalSince1970: 2_000)
        )

        try harness.repository.saveEvent(.sleep(earlierSleep))
        try harness.repository.saveEvent(.sleep(activeSleep))

        let loadedSleep = try #require(
            try harness.repository.loadActiveSleepEvent(for: childID)
        )

        #expect(loadedSleep.id == activeSleep.id)
        #expect(loadedSleep.endedAt == nil)
    }

    @Test
    func breastFeedEventsRoundTripOptionalAndBothSides() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let childID = UUID()
        let userID = UUID()
        let firstStart = Date(timeIntervalSince1970: 4_000)
        let firstEnd = firstStart.addingTimeInterval(900)
        let secondStart = Date(timeIntervalSince1970: 6_000)
        let secondEnd = secondStart.addingTimeInterval(1_200)

        let noSideFeed = try BreastFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: firstEnd,
                createdAt: firstEnd,
                createdBy: userID
            ),
            side: nil,
            startedAt: firstStart,
            endedAt: firstEnd
        )
        let bothSidesFeed = try BreastFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: secondEnd,
                createdAt: secondEnd,
                createdBy: userID
            ),
            side: .both,
            startedAt: secondStart,
            endedAt: secondEnd
        )

        try harness.repository.saveEvent(.breastFeed(noSideFeed))
        try harness.repository.saveEvent(.breastFeed(bothSidesFeed))

        let timeline = try harness.repository.loadTimeline(for: childID, includingDeleted: false)
        let reloadedNoSideFeed = try #require(try harness.repository.loadEvent(id: noSideFeed.id))
        let reloadedBothSidesFeed = try #require(try harness.repository.loadEvent(id: bothSidesFeed.id))

        #expect(timeline.map(\.kind) == [.breastFeed, .breastFeed])

        switch reloadedNoSideFeed {
        case let .breastFeed(event):
            #expect(event.side == nil)
        default:
            Issue.record("Expected a breast feed event without a side")
        }

        switch reloadedBothSidesFeed {
        case let .breastFeed(event):
            #expect(event.side == .both)
        default:
            Issue.record("Expected a breast feed event with both sides")
        }
    }
}

extension EventRepositoryTests {
    @MainActor
    private struct RepositoryHarness {
        let store: BabyTrackerModelStore
        let repository: SwiftDataEventRepository

        init() throws {
            let store = try BabyTrackerModelStore(isStoredInMemoryOnly: true)
            self.store = store
            self.repository = SwiftDataEventRepository(store: store)
        }

        func cleanUp() {}
    }
}
