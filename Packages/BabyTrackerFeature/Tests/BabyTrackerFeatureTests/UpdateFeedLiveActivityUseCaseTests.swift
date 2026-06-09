@testable import BabyTrackerFeature
import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct UpdateFeedLiveActivityUseCaseTests {
    // MARK: - Helpers

    private func makeChild() throws -> Child {
        try Child(name: "Robin", createdBy: UUID())
    }

    private func makeBottleFeedEvent(childID: UUID, occurredAt: Date = .now) throws -> BabyEvent {
        .bottleFeed(try BottleFeedEvent(
            metadata: EventMetadata(childID: childID, occurredAt: occurredAt, createdBy: UUID()),
            amountMilliliters: 120
        ))
    }

    private func execute(
        events: [BabyEvent],
        child: Child?,
        isLiveActivityEnabled: Bool = true,
        manager: SpyFeedLiveActivityManager
    ) {
        UpdateFeedLiveActivityUseCase.execute(
            events: events,
            child: child,
            activeSleep: nil,
            isLiveActivityEnabled: isLiveActivityEnabled,
            liveActivityManager: manager
        )
    }

    // MARK: - Synchronizing a snapshot

    @Test
    func synchronizesSnapshotWhenEnabledAndChildExists() throws {
        let manager = SpyFeedLiveActivityManager()
        let child = try makeChild()
        let events = [try makeBottleFeedEvent(childID: child.id)]

        execute(events: events, child: child, manager: manager)

        #expect(manager.synchronizeCalls.count == 1)
        let snapshot = try #require(manager.synchronizeCalls.last ?? nil)
        #expect(snapshot.childID == child.id)
        #expect(snapshot.lastFeedKind == .bottleFeed)
    }

    /// Deduplication is the manager's responsibility (against the activity's real
    /// content), so the use case forwards every call — it must never skip one.
    @Test
    func forwardsEveryUpdateWithoutDeduping() throws {
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
    func endsActivityWhenNoFeedData() throws {
        let manager = SpyFeedLiveActivityManager()
        let child = try makeChild()

        execute(events: [], child: child, manager: manager)

        #expect(manager.synchronizeCalls.count == 1)
        #expect(manager.synchronizeCalls.last == .some(nil))
    }
}
