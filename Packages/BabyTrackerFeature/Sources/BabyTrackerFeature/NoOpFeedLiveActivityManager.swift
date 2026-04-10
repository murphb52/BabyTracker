import Foundation

@MainActor
public final class NoOpFeedLiveActivityManager: FeedLiveActivityManaging {
    public init() {}

    public func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        _ = snapshot
    }

    public func forceSync(with snapshot: FeedLiveActivitySnapshot?) {
        _ = snapshot
    }
}
