import Foundation

@MainActor
public protocol FeedLiveActivityManaging: AnyObject {
    func synchronize(with snapshot: FeedLiveActivitySnapshot?)
}
