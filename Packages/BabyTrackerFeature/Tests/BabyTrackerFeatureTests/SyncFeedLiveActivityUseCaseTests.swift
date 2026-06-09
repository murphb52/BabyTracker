@testable import BabyTrackerFeature
import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct SyncFeedLiveActivityUseCaseTests {
    // MARK: - Helpers

    private func makeChild() throws -> Child {
        try Child(name: "Robin", createdBy: UUID())
    }

    private func makeBottleFeedEvent(
        childID: UUID,
        occurredAt: Date = Date(timeIntervalSince1970: 2_000)
    ) throws -> BabyEvent {
        .bottleFeed(try BottleFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: occurredAt,
                createdAt: occurredAt,
                createdBy: UUID()
            ),
            amountMilliliters: 120
        ))
    }

    private func execute(
        events: [BabyEvent],
        child: Child?,
        activeSleep: SleepEvent? = nil,
        isLiveActivityEnabled: Bool = true,
        manager: SpyFeedLiveActivityManager
    ) {
        SyncFeedLiveActivityUseCase.execute(
            events: events,
            child: child,
            activeSleep: activeSleep,
            isLiveActivityEnabled: isLiveActivityEnabled,
            liveActivityManager: manager
        )
    }

    // MARK: - Synchronizing a snapshot

    @Test
    func synchronizesSnapshotWhenEnabledAndChildHasFeedData() throws {
        let manager = SpyFeedLiveActivityManager()
        let child = try makeChild()
        let feedTime = Date(timeIntervalSince1970: 2_000)
        let events = [try makeBottleFeedEvent(childID: child.id, occurredAt: feedTime)]

        execute(events: events, child: child, manager: manager)

        #expect(manager.synchronizeCalls.count == 1)
        let snapshot = try #require(manager.latestSnapshot)
        #expect(snapshot.childID == child.id)
        #expect(snapshot.childName == child.name)
        #expect(snapshot.lastFeedKind == .bottleFeed)
        #expect(snapshot.lastFeedAt == feedTime)
    }

    @Test
    func snapshotCarriesActiveSleepStart() throws {
        let manager = SpyFeedLiveActivityManager()
        let child = try makeChild()
        let sleepStart = Date(timeIntervalSince1970: 3_000)
        let activeSleep = try SleepEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: sleepStart,
                createdAt: sleepStart,
                createdBy: UUID()
            ),
            startedAt: sleepStart
        )
        let events: [BabyEvent] = [
            try makeBottleFeedEvent(childID: child.id),
            .sleep(activeSleep),
        ]

        execute(events: events, child: child, activeSleep: activeSleep, manager: manager)

        let snapshot = try #require(manager.latestSnapshot)
        #expect(snapshot.activeSleepStartedAt == sleepStart)
    }

    /// Deduplication belongs to the manager (against the activity's real
    /// content), so the use case must forward every call unchanged.
    @Test
    func forwardsEveryCallWithoutDeduping() throws {
        let manager = SpyFeedLiveActivityManager()
        let child = try makeChild()
        let events = [try makeBottleFeedEvent(childID: child.id)]

        execute(events: events, child: child, manager: manager)
        execute(events: events, child: child, manager: manager)

        #expect(manager.synchronizeCalls.count == 2)
        #expect(manager.synchronizeCalls.allSatisfy { $0 != nil })
    }

    // MARK: - Ending the activity

    @Test
    func endsActivityWhenDisabled() throws {
        let manager = SpyFeedLiveActivityManager()
        let child = try makeChild()
        let events = [try makeBottleFeedEvent(childID: child.id)]

        execute(events: events, child: child, isLiveActivityEnabled: false, manager: manager)

        #expect(manager.synchronizeCalls.count == 1)
        #expect(manager.synchronizeCalls.last == .some(nil))
    }

    @Test
    func endsActivityWhenChildIsNil() throws {
        let manager = SpyFeedLiveActivityManager()
        let child = try makeChild()
        let events = [try makeBottleFeedEvent(childID: child.id)]

        execute(events: events, child: nil, manager: manager)

        #expect(manager.synchronizeCalls.count == 1)
        #expect(manager.synchronizeCalls.last == .some(nil))
    }

    @Test
    func endsActivityWhenNoFeedDataExists() throws {
        let manager = SpyFeedLiveActivityManager()
        let child = try makeChild()

        execute(events: [], child: child, manager: manager)

        #expect(manager.synchronizeCalls.count == 1)
        #expect(manager.synchronizeCalls.last == .some(nil))
    }

    // MARK: - Snapshot construction

    @Test
    func makeSnapshotReturnsNilWithoutFeedData() throws {
        let child = try makeChild()

        let snapshot = SyncFeedLiveActivityUseCase.makeSnapshot(
            events: [],
            child: child,
            activeSleep: nil,
            isLiveActivityEnabled: true
        )

        #expect(snapshot == nil)
    }

    @Test
    func makeSnapshotUsesSleepEndOverStart() throws {
        let child = try makeChild()
        let sleepStart = Date(timeIntervalSince1970: 3_000)
        let sleepEnd = Date(timeIntervalSince1970: 4_000)
        let sleep = try SleepEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: sleepEnd,
                createdAt: sleepEnd,
                createdBy: UUID()
            ),
            startedAt: sleepStart,
            endedAt: sleepEnd
        )
        let events: [BabyEvent] = [
            try makeBottleFeedEvent(childID: child.id),
            .sleep(sleep),
        ]

        let snapshot = try #require(SyncFeedLiveActivityUseCase.makeSnapshot(
            events: events,
            child: child,
            activeSleep: nil,
            isLiveActivityEnabled: true
        ))

        #expect(snapshot.lastSleepAt == sleepEnd)
        #expect(snapshot.activeSleepStartedAt == nil)
    }
}
