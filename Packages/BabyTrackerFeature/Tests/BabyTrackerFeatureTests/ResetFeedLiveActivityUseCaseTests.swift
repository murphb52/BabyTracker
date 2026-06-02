@testable import BabyTrackerFeature
import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct ResetFeedLiveActivityUseCaseTests {
    // MARK: - Helpers

    private func makeSnapshot() -> FeedLiveActivitySnapshot {
        FeedLiveActivitySnapshot(
            childID: UUID(),
            childName: "Robin",
            lastFeedKind: .bottleFeed,
            lastFeedAt: .now,
            lastSleepAt: nil,
            activeSleepStartedAt: nil,
            lastNappyAt: nil
        )
    }

    // MARK: - Activity running

    @Test
    func synchronizesManagerWithNilWhenActivityIsRunning() {
        let cache = InMemoryFeedLiveActivitySnapshotCache()
        let manager = SpyFeedLiveActivityManager(snapshotCache: cache)
        manager.hasRunningActivity = true
        cache.save(makeSnapshot())

        ResetFeedLiveActivityUseCase.execute(liveActivityManager: manager)

        #expect(manager.synchronizeCalls.count == 1)
        #expect(manager.synchronizeCalls.first == .some(nil))
    }

    @Test
    func clearsCacheWhenActivityIsRunning() {
        let cache = InMemoryFeedLiveActivitySnapshotCache()
        let manager = SpyFeedLiveActivityManager(snapshotCache: cache)
        manager.hasRunningActivity = true
        cache.save(makeSnapshot())

        ResetFeedLiveActivityUseCase.execute(liveActivityManager: manager)

        #expect(cache.load() == nil)
    }

    // MARK: - No activity running

    @Test
    func doesNothingWhenNoActivityIsRunning() {
        let manager = SpyFeedLiveActivityManager()

        ResetFeedLiveActivityUseCase.execute(liveActivityManager: manager)

        #expect(manager.synchronizeCalls.isEmpty)
    }

    // MARK: - Integration with UpdateFeedLiveActivityUseCase

    @Test
    func allowsSubsequentUpdateToWriteAfterReset() throws {
        let cache = InMemoryFeedLiveActivitySnapshotCache()
        let manager = SpyFeedLiveActivityManager(snapshotCache: cache)
        let child = try Child(name: "Robin", createdBy: UUID())
        let events: [BabyEvent] = [.bottleFeed(try BottleFeedEvent(
            metadata: EventMetadata(childID: child.id, occurredAt: .now, createdBy: UUID()),
            amountMilliliters: 120
        ))]

        // First update — starts the activity and populates the cache
        UpdateFeedLiveActivityUseCase.execute(
            events: events,
            child: child,
            activeSleep: nil,
            isLiveActivityEnabled: true,
            liveActivityManager: manager,
            snapshotCache: cache
        )

        // Second update with same data — skipped by the cache
        UpdateFeedLiveActivityUseCase.execute(
            events: events,
            child: child,
            activeSleep: nil,
            isLiveActivityEnabled: true,
            liveActivityManager: manager,
            snapshotCache: cache
        )

        let callsBeforeReset = manager.synchronizeCalls.count

        // Reset ends the running activity, and the manager clears the cache
        ResetFeedLiveActivityUseCase.execute(liveActivityManager: manager)

        // Same data again — goes through because the cache was cleared by reset
        UpdateFeedLiveActivityUseCase.execute(
            events: events,
            child: child,
            activeSleep: nil,
            isLiveActivityEnabled: true,
            liveActivityManager: manager,
            snapshotCache: cache
        )

        // Reset's nil synchronize + post-reset update both produced calls
        #expect(manager.synchronizeCalls.count == callsBeforeReset + 2)
    }
}
