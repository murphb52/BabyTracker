import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

@MainActor
struct UpdateFeedLiveActivityUseCaseTests {
    @Test
    func endsLiveActivityWhenPreferenceIsDisabled() throws {
        let spy = LiveActivityManagerSpy()
        let context = try makeContext()

        UpdateFeedLiveActivityUseCase.execute(
            events: context.events,
            child: context.child,
            activeSleep: nil,
            isLiveActivityEnabled: false,
            liveActivityManager: spy,
            snapshotCache: InMemoryFeedLiveActivitySnapshotCache()
        )

        #expect(spy.latestSnapshot == nil)
        #expect(spy.snapshots.count == 1)
    }

    @Test
    func endsLiveActivityWhenChildIsMissing() throws {
        let spy = LiveActivityManagerSpy()
        let context = try makeContext()

        UpdateFeedLiveActivityUseCase.execute(
            events: context.events,
            child: nil,
            activeSleep: nil,
            isLiveActivityEnabled: true,
            liveActivityManager: spy,
            snapshotCache: InMemoryFeedLiveActivitySnapshotCache()
        )

        #expect(spy.latestSnapshot == nil)
        #expect(spy.snapshots.count == 1)
    }

    @Test
    func synchronizesSnapshotWhenEnabledAndChildExists() throws {
        let spy = LiveActivityManagerSpy()
        let context = try makeContext()

        UpdateFeedLiveActivityUseCase.execute(
            events: context.events,
            child: context.child,
            activeSleep: nil,
            isLiveActivityEnabled: true,
            liveActivityManager: spy,
            snapshotCache: InMemoryFeedLiveActivitySnapshotCache()
        )

        let snapshot = try #require(spy.latestSnapshot)
        #expect(snapshot.childID == context.child.id)
        #expect(snapshot.lastFeedKind == .bottleFeed)
        #expect(snapshot.lastFeedAt == context.feedTime)
    }

    private func makeContext() throws -> (child: Child, events: [BabyEvent], feedTime: Date) {
        let childID = UUID()
        let userID = UUID()
        let feedTime = Date(timeIntervalSince1970: 2_000)

        let child = try Child(
            id: childID,
            name: "Luna",
            createdAt: Date(timeIntervalSince1970: 1_000),
            createdBy: userID
        )

        let events: [BabyEvent] = [
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: feedTime,
                        createdAt: feedTime,
                        createdBy: userID
                    ),
                    amountMilliliters: 120
                )
            ),
        ]

        return (child, events, feedTime)
    }
}

@MainActor
private final class LiveActivityManagerSpy: FeedLiveActivityManaging {
    private(set) var snapshots: [FeedLiveActivitySnapshot?] = []

    var latestSnapshot: FeedLiveActivitySnapshot? {
        snapshots.last ?? nil
    }

    func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        snapshots.append(snapshot)
    }
}
