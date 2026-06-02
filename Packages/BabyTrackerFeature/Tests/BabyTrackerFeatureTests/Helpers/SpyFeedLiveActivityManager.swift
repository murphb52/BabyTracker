@testable import BabyTrackerFeature

/// Test double mirroring `FeedLiveActivityManager`'s contract: the manager owns
/// the snapshot cache and only advances it once an activity is actually running.
/// When constructed with a cache, `synchronize` writes through to it (and toggles
/// `hasRunningActivity`) so the dedup behaviour under test matches production.
@MainActor
final class SpyFeedLiveActivityManager: FeedLiveActivityManaging {
    var hasRunningActivity: Bool = false
    private(set) var synchronizeCalls: [FeedLiveActivitySnapshot?] = []
    private let snapshotCache: (any FeedLiveActivitySnapshotCaching)?

    init(snapshotCache: (any FeedLiveActivitySnapshotCaching)? = nil) {
        self.snapshotCache = snapshotCache
    }

    func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        synchronizeCalls.append(snapshot)
        snapshotCache?.save(snapshot)
        hasRunningActivity = snapshot != nil
    }
}
