@testable import BabyTrackerFeature

/// Records every snapshot the use case asks it to synchronize, including the
/// `nil` "end the activity" calls.
@MainActor
final class SpyFeedLiveActivityManager: FeedLiveActivityManaging {
    private(set) var synchronizeCalls: [FeedLiveActivitySnapshot?] = []

    var latestSnapshot: FeedLiveActivitySnapshot? {
        synchronizeCalls.last ?? nil
    }

    func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        synchronizeCalls.append(snapshot)
    }
}
