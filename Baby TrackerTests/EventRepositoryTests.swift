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

    @Test
    func nappyEventsRoundTripOptionalFields() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let childID = UUID()
        let userID = UUID()
        let dryTime = Date(timeIntervalSince1970: 6_500)
        let mixedTime = Date(timeIntervalSince1970: 7_500)

        let dryNappy = try NappyEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: dryTime,
                createdAt: dryTime,
                createdBy: userID
            ),
            type: .dry
        )
        let mixedNappy = try NappyEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: mixedTime,
                createdAt: mixedTime,
                createdBy: userID
            ),
            type: .mixed,
            pooVolume: .heavy,
            pooColor: .green
        )

        try harness.repository.saveEvent(.nappy(dryNappy))
        try harness.repository.saveEvent(.nappy(mixedNappy))

        let timeline = try harness.repository.loadTimeline(for: childID, includingDeleted: false)
        let reloadedDryNappy = try #require(try harness.repository.loadEvent(id: dryNappy.id))
        let reloadedMixedNappy = try #require(try harness.repository.loadEvent(id: mixedNappy.id))

        #expect(timeline.map(\.kind) == [.nappy, .nappy])

        switch reloadedDryNappy {
        case let .nappy(event):
            #expect(event.peeVolume == nil)
            #expect(event.pooVolume == nil)
            #expect(event.pooColor == nil)
        default:
            Issue.record("Expected a dry nappy event")
        }

        switch reloadedMixedNappy {
        case let .nappy(event):
            #expect(event.pooVolume == .heavy)
            #expect(event.pooColor == .green)
        default:
            Issue.record("Expected a mixed nappy event")
        }
    }

    @Test
    func savingEditedEventUpdatesExistingRecordInPlace() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let childID = UUID()
        let userID = UUID()
        let occurredAt = Date(timeIntervalSince1970: 7_000)
        let original = try BottleFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: occurredAt,
                createdAt: occurredAt,
                createdBy: userID
            ),
            amountMilliliters: 120
        )

        try harness.repository.saveEvent(.bottleFeed(original))

        let updated = try original.updating(
            amountMilliliters: 150,
            occurredAt: occurredAt.addingTimeInterval(600),
            milkType: .formula,
            updatedBy: userID
        )
        try harness.repository.saveEvent(.bottleFeed(updated))

        let timeline = try harness.repository.loadTimeline(for: childID, includingDeleted: false)
        let reloadedEvent = try #require(try harness.repository.loadEvent(id: original.id))

        #expect(timeline.count == 1)

        switch reloadedEvent {
        case let .bottleFeed(event):
            #expect(event.id == original.id)
            #expect(event.amountMilliliters == 150)
            #expect(event.milkType == .formula)
            #expect(event.metadata.occurredAt == occurredAt.addingTimeInterval(600))
        default:
            Issue.record("Expected an updated bottle feed event")
        }
    }

    @Test
    func softDeletedEventCanBeRestoredBySavingItAgain() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let childID = UUID()
        let userID = UUID()
        let occurredAt = Date(timeIntervalSince1970: 8_000)
        let original = try BottleFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: occurredAt,
                createdAt: occurredAt,
                createdBy: userID
            ),
            amountMilliliters: 120
        )

        try harness.repository.saveEvent(.bottleFeed(original))
        try harness.repository.softDeleteEvent(
            id: original.id,
            deletedAt: occurredAt.addingTimeInterval(60),
            deletedBy: userID
        )

        let deletedEvent = try #require(try harness.repository.loadEvent(id: original.id))

        switch deletedEvent {
        case var .bottleFeed(event):
            event.metadata.restoreDeleted(by: userID)
            try harness.repository.saveEvent(.bottleFeed(event))
        default:
            Issue.record("Expected a deleted bottle feed event")
        }

        let visibleTimeline = try harness.repository.loadTimeline(for: childID, includingDeleted: false)
        let reloadedEvent = try #require(try harness.repository.loadEvent(id: original.id))

        #expect(visibleTimeline.count == 1)

        switch reloadedEvent {
        case let .bottleFeed(event):
            #expect(event.metadata.isDeleted == false)
            #expect(event.metadata.deletedAt == nil)
        default:
            Issue.record("Expected a restored bottle feed event")
        }
    }

    @Test
    func loadEventsUsesOccurredAtDayForSleepThatSpansMidnight() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let childID = UUID()
        let userID = UUID()
        let calendar = Calendar(identifier: .gregorian)
        let dayOne = Date(timeIntervalSince1970: 1_728_000_000)
        let startOfDayOne = calendar.startOfDay(for: dayOne)
        let startOfDayTwo = try #require(
            calendar.date(byAdding: .day, value: 1, to: startOfDayOne)
        )
        let sleepStart = try #require(
            calendar.date(byAdding: .hour, value: 23, to: startOfDayOne)
        )
        let sleepEnd = try #require(
            calendar.date(byAdding: .hour, value: 1, to: startOfDayTwo)
        )

        let sleep = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: sleepEnd,
                createdAt: sleepEnd,
                createdBy: userID
            ),
            startedAt: sleepStart,
            endedAt: sleepEnd
        )

        try harness.repository.saveEvent(.sleep(sleep))

        let firstDayEvents = try harness.repository.loadEvents(
            for: childID,
            on: startOfDayOne,
            calendar: calendar,
            includingDeleted: false
        )
        let secondDayEvents = try harness.repository.loadEvents(
            for: childID,
            on: startOfDayTwo,
            calendar: calendar,
            includingDeleted: false
        )

        #expect(firstDayEvents.isEmpty)
        #expect(secondDayEvents.map(\.id) == [sleep.id])
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
