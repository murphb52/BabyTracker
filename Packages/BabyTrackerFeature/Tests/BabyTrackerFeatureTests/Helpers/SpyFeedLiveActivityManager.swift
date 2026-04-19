@testable import BabyTrackerFeature

@MainActor
final class SpyFeedLiveActivityManager: FeedLiveActivityManaging {
    var hasRunningActivity: Bool = false
    private(set) var synchronizeCalls: [FeedLiveActivitySnapshot?] = []

    func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        synchronizeCalls.append(snapshot)
    }
}
