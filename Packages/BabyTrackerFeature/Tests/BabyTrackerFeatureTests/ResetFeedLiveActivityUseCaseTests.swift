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

    // MARK: - Cache has data

    @Test
    func synchronizesManagerWithNilWhenCacheHasData() {
        let manager = SpyFeedLiveActivityManager()
        let cache = InMemoryFeedLiveActivitySnapshotCache()
        cache.save(makeSnapshot())

        ResetFeedLiveActivityUseCase.execute(liveActivityManager: manager, snapshotCache: cache)

        #expect(manager.synchronizeCalls.count == 1)
        #expect(manager.synchronizeCalls.first == .some(nil))
    }

    @Test
    func clearsCacheWhenCacheHasData() {
        let manager = SpyFeedLiveActivityManager()
        let cache = InMemoryFeedLiveActivitySnapshotCache()
        cache.save(makeSnapshot())

        ResetFeedLiveActivityUseCase.execute(liveActivityManager: manager, snapshotCache: cache)

        #expect(cache.load() == nil)
    }

    // MARK: - Cache is empty

    @Test
    func doesNothingWhenCacheIsEmpty() {
        let manager = SpyFeedLiveActivityManager()
        let cache = InMemoryFeedLiveActivitySnapshotCache()

        ResetFeedLiveActivityUseCase.execute(liveActivityManager: manager, snapshotCache: cache)

        #expect(manager.synchronizeCalls.isEmpty)
    }

    // MARK: - Integration with UpdateFeedLiveActivityUseCase

    @Test
    func allowsSubsequentUpdateToWriteAfterReset() throws {
        let manager = SpyFeedLiveActivityManager()
        let cache = InMemoryFeedLiveActivitySnapshotCache()
        let child = try Child(name: "Robin", createdBy: UUID())
        let events: [BabyEvent] = [.bottleFeed(try BottleFeedEvent(
            metadata: EventMetadata(childID: child.id, occurredAt: .now, createdBy: UUID()),
            amountMilliliters: 120
        ))]

        // First update — populates cache
        UpdateFeedLiveActivityUseCase.execute(
            events: events,
            child: child,
            activeSleep: nil,
            isLiveActivityEnabled: true,
            liveActivityManager: manager,
            snapshotCache: cache
        )

        // Second update with same data — skipped by cache
        UpdateFeedLiveActivityUseCase.execute(
            events: events,
            child: child,
            activeSleep: nil,
            isLiveActivityEnabled: true,
            liveActivityManager: manager,
            snapshotCache: cache
        )

        let callsBeforeReset = manager.synchronizeCalls.count

        // Reset ends the activity and clears the cache
        ResetFeedLiveActivityUseCase.execute(liveActivityManager: manager, snapshotCache: cache)

        // Same data again — goes through because cache was cleared by reset
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
