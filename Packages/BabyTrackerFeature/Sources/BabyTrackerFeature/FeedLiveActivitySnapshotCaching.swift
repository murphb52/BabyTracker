import Foundation

@MainActor
public protocol FeedLiveActivitySnapshotCaching: AnyObject {
    func load() -> FeedLiveActivitySnapshot?
    func save(_ snapshot: FeedLiveActivitySnapshot?)
}
