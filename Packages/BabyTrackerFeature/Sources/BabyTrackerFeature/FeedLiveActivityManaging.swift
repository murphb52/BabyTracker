import Foundation

/// Boundary between the feature layer and ActivityKit.
///
/// `synchronize(with:)` declares the desired end state; the implementation
/// owns every ActivityKit policy decision (starting, updating, restarting to
/// renew the system's update budget, foreground gating, deduplication).
/// A `nil` snapshot means "no activity should be showing".
@MainActor
public protocol FeedLiveActivityManaging: AnyObject {
    func synchronize(with snapshot: FeedLiveActivitySnapshot?)
}
