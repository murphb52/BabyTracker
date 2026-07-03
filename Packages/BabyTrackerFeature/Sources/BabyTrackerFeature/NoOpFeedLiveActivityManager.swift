/// Used in previews, tests, and UI-test launches where ActivityKit must not
/// be touched.
@MainActor
public final class NoOpFeedLiveActivityManager: FeedLiveActivityManaging {
    public init() {}

    public func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        _ = snapshot
    }
}
