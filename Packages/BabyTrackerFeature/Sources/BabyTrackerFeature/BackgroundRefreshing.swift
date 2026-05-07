import BabyTrackerDomain
import Foundation

/// Decouples the background-refresh use case from `AppModel` so it can be
/// tested without spinning up the full feature graph.
@MainActor
public protocol BackgroundRefreshing: AnyObject {
    func refreshAfterRemoteNotification(isAppInBackground: Bool) async -> SyncStatusSummary
}
