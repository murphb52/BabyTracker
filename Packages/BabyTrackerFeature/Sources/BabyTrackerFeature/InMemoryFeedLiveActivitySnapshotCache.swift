import Foundation

@MainActor
public final class InMemoryFeedLiveActivitySnapshotCache: FeedLiveActivitySnapshotCaching {
    private var snapshot: FeedLiveActivitySnapshot?

    public init() {}

    public func load() -> FeedLiveActivitySnapshot? { snapshot }

    public func save(_ snapshot: FeedLiveActivitySnapshot?) { self.snapshot = snapshot }
}
