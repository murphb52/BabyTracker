import Foundation

@MainActor
public protocol FeedLiveActivityManaging: AnyObject {
    func synchronize(with snapshot: FeedLiveActivitySnapshot?)
    /// Ends any existing activity and starts a completely fresh one from the given snapshot.
    /// Use this on app launch and after sync events to avoid stale activity state.
    func forceSync(with snapshot: FeedLiveActivitySnapshot?)
}
