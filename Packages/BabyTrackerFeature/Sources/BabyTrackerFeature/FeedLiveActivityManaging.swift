import Foundation

@MainActor
public protocol FeedLiveActivityManaging: AnyObject {
    var hasRunningActivity: Bool { get }
    func synchronize(with snapshot: FeedLiveActivitySnapshot?)
}
