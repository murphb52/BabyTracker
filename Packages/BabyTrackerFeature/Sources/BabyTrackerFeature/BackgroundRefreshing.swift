import BabyTrackerDomain
import Foundation

/// Decouples the background-refresh use case from `AppModel` so it can be
/// tested without spinning up the full feature graph.
@MainActor
public protocol BackgroundRefreshing: AnyObject {
    /// - Parameter timeout: How long to wait before reporting back regardless.
    ///   A background wake-up that misses iOS's window is killed and throttled,
    ///   so the caller always needs an answer in time.
    func refreshAfterRemoteNotification(
        isAppInBackground: Bool,
        timeout: Duration
    ) async -> SyncStatusSummary
}
