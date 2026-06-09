@testable import BabyTrackerFeature

/// Records the snapshots it is asked to synchronize and mirrors the real manager's
/// running-state contract: a non-nil snapshot starts/keeps an activity running, a
/// nil snapshot ends it.
@MainActor
final class SpyFeedLiveActivityManager: FeedLiveActivityManaging {
    var hasRunningActivity: Bool = false
    private(set) var synchronizeCalls: [FeedLiveActivitySnapshot?] = []

    func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        synchronizeCalls.append(snapshot)
        hasRunningActivity = snapshot != nil
    }
}
