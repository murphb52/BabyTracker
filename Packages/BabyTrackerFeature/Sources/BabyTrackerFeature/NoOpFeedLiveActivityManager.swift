import Foundation

@MainActor
public final class NoOpFeedLiveActivityManager: FeedLiveActivityManaging {
    public init() {}

    public var hasRunningActivity: Bool { false }

    public func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        _ = snapshot
    }
}
