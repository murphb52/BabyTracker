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
        manager: SpyFeedLiveActivityManager,
        cache: InMemoryFeedLiveActivitySnapshotCache
    ) {
        UpdateFeedLiveActivityUseCase.execute(
            events: events,
            child: child,
            activeSleep: nil,
            isLiveActivityEnabled: isLiveActivityEnabled,
            liveActivityManager: manager,
            snapshotCache: cache
        )
    }

    // MARK: - Cache hit: skip

    @Test
    func skipsWriteWhenSnapshotMatchesCache() throws {
        let manager = SpyFeedLiveActivityManager()
        let cache = InMemoryFeedLiveActivitySnapshotCache()
        let child = try makeChild()
        let events = [try makeBottleFeedEvent(childID: child.id)]

        // First call — populates the cache
        execute(events: events, child: child, manager: manager, cache: cache)
        let callsAfterFirst = manager.synchronizeCalls.count

        // Second call with identical data — should be skipped
        execute(events: events, child: child, manager: manager, cache: cache)

        #expect(manager.synchronizeCalls.count == callsAfterFirst)
    }

    @Test
    func doesNotUpdateCacheWhenSkipped() throws {
        let manager = SpyFeedLiveActivityManager()
        let cache = InMemoryFeedLiveActivitySnapshotCache()
        let child = try makeChild()
        let events = [try makeBottleFeedEvent(childID: child.id)]

        execute(events: events, child: child, manager: manager, cache: cache)
        let snapshotAfterFirst = cache.load()

        execute(events: events, child: child, manager: manager, cache: cache)

        #expect(cache.load() == snapshotAfterFirst)
    }

    // MARK: - Cache miss: write

    @Test
    func writesWhenCacheIsEmpty() throws {
        let manager = SpyFeedLiveActivityManager()
        let cache = InMemoryFeedLiveActivitySnapshotCache()
        let child = try makeChild()
        let events = [try makeBottleFeedEvent(childID: child.id)]

        execute(events: events, child: child, manager: manager, cache: cache)

        #expect(manager.synchronizeCalls.count == 1)
    }

    @Test
    func writesWhenSnapshotDiffersFromCache() throws {
        let manager = SpyFeedLiveActivityManager()
        let cache = InMemoryFeedLiveActivitySnapshotCache()
        let child = try makeChild()

        execute(
            events: [try makeBottleFeedEvent(childID: child.id, occurredAt: .now)],
            child: child,
            manager: manager,
            cache: cache
        )

        // Different feed time → different snapshot
        execute(
            events: [try makeBottleFeedEvent(childID: child.id, occurredAt: .now.addingTimeInterval(3_600))],
            child: child,
            manager: manager,
            cache: cache
        )

        #expect(manager.synchronizeCalls.count == 2)
    }

    @Test
    func updatesCacheAfterWrite() throws {
        let manager = SpyFeedLiveActivityManager()
        let cache = InMemoryFeedLiveActivitySnapshotCache()
        let child = try makeChild()
        let events = [try makeBottleFeedEvent(childID: child.id)]

        #expect(cache.load() == nil)

        execute(events: events, child: child, manager: manager, cache: cache)

        #expect(cache.load() != nil)
    }

    // MARK: - Disabled / no child

    @Test
    func synchronizesNilAndClearsCacheWhenDisabled() throws {
        let manager = SpyFeedLiveActivityManager()
        let cache = InMemoryFeedLiveActivitySnapshotCache()
        let child = try makeChild()
        let events = [try makeBottleFeedEvent(childID: child.id)]

        // Populate cache first
        execute(events: events, child: child, manager: manager, cache: cache)

        execute(events: events, child: child, isLiveActivityEnabled: false, manager: manager, cache: cache)

        #expect(manager.synchronizeCalls.last == nil)
        #expect(cache.load() == nil)
    }

    @Test
    func synchronizesNilAndClearsCacheWhenChildIsNil() throws {
        let manager = SpyFeedLiveActivityManager()
        let cache = InMemoryFeedLiveActivitySnapshotCache()
        let child = try makeChild()
        let events = [try makeBottleFeedEvent(childID: child.id)]

        // Populate cache first
        execute(events: events, child: child, manager: manager, cache: cache)

        execute(events: events, child: nil, manager: manager, cache: cache)

        #expect(manager.synchronizeCalls.last == nil)
        #expect(cache.load() == nil)
    }
}
