import ActivityKit
import BabyTrackerDomain
import BabyTrackerFeature
import BabyTrackerLiveActivities
import Foundation
import UIKit

/// Owns the ActivityKit lifecycle for the feed Live Activity.
///
/// iOS only applies `Activity.update` for roughly 8 hours after
/// `Activity.request`, and removes the activity entirely after ~12 hours.
/// A baby-tracking activity must outlive that, so whenever the app is in the
/// foreground and the running activity is older than `restartAge`, this
/// manager ends it and requests a fresh one — renewing the system's update
/// budget on every realistic app visit. An activity that is never renewed is
/// exactly what used to leave stale data frozen on the lock screen.
@MainActor
final class FeedLiveActivityManager: FeedLiveActivityManaging {
    /// Restart a foreground-reconciled activity once it is this old. Kept far
    /// below the ~8h update ceiling so the budget is renewed long before it
    /// can expire.
    private let restartAge: TimeInterval = 60 * 60

    // Latest-wins mailbox: `.some(snapshot)` is a queued reconcile (whose
    // payload may itself be nil = "end the activity"); nil means nothing
    // pending. A newer snapshot replaces the queued one — in-flight
    // ActivityKit writes are always awaited to completion, never cancelled.
    private var queuedSnapshot: FeedLiveActivitySnapshot??
    private var isReconciling = false

    func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        queuedSnapshot = .some(snapshot)

        guard !isReconciling else {
            return
        }

        isReconciling = true
        Task { @MainActor [weak self] in
            await self?.reconcileQueuedSnapshots()
        }
    }

    private func reconcileQueuedSnapshots() async {
        defer { isReconciling = false }
        while let snapshot = queuedSnapshot {
            queuedSnapshot = nil
            await reconcile(snapshot)
        }
    }

    private func reconcile(_ snapshot: FeedLiveActivitySnapshot?) async {
        guard let snapshot else {
            await endAllActivities()
            return
        }

        let existingActivity = await endAllActivitiesExceptFirst(matching: snapshot.childID)

        // ActivityKit rejects `Activity.request` from the background; updates
        // to a running activity are always allowed.
        let canStartActivity = UIApplication.shared.applicationState != .background

        guard let existingActivity else {
            if canStartActivity {
                startActivity(with: snapshot)
            } else {
                log(.debug, "No running activity and app is backgrounded — start deferred to next foreground sync")
            }
            return
        }

        if canStartActivity && hasOutlivedRestartAge(existingActivity) {
            log(.info, "Restarting activity \(existingActivity.id) to renew the system update budget")
            await existingActivity.end(nil, dismissalPolicy: .immediate)
            startActivity(with: snapshot)
            return
        }

        let content = Self.makeContent(for: snapshot)
        if existingActivity.content.state != content.state {
            await existingActivity.update(content)
            log(.info, "Updated activity \(existingActivity.id)")
        }
    }

    private func startActivity(with snapshot: FeedLiveActivitySnapshot) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            log(.error, "Cannot start Live Activity — disabled in system settings (areActivitiesEnabled == false)")
            return
        }

        do {
            let activity = try Activity.request(
                attributes: FeedLiveActivityAttributes(
                    childID: snapshot.childID,
                    startedAt: .now
                ),
                content: Self.makeContent(for: snapshot),
                pushType: nil
            )
            log(.info, "Started activity \(activity.id) for child \(snapshot.childID)")
        } catch {
            log(.error, "Activity.request failed: \(error)")
        }
    }

    /// Activities without a `startedAt` were started by builds that never
    /// renewed the update budget, so their age is unknown — treat them as
    /// expired.
    private func hasOutlivedRestartAge(_ activity: Activity<FeedLiveActivityAttributes>) -> Bool {
        guard let startedAt = activity.attributes.startedAt else {
            return true
        }
        return Date.now.timeIntervalSince(startedAt) > restartAge
    }

    /// Ends every running activity except the first one for `childID` (stray
    /// duplicates and activities for other children must not linger), and
    /// returns the survivor.
    private func endAllActivitiesExceptFirst(
        matching childID: UUID
    ) async -> Activity<FeedLiveActivityAttributes>? {
        var matchingActivity: Activity<FeedLiveActivityAttributes>?

        for activity in Activity<FeedLiveActivityAttributes>.activities {
            if matchingActivity == nil && activity.attributes.childID == childID {
                matchingActivity = activity
            } else {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }

        return matchingActivity
    }

    private func endAllActivities() async {
        let activities = Activity<FeedLiveActivityAttributes>.activities
        guard !activities.isEmpty else {
            return
        }

        log(.info, "Ending \(activities.count) activity(ies)")
        for activity in activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private static func makeContent(
        for snapshot: FeedLiveActivitySnapshot
    ) -> ActivityContent<FeedLiveActivityAttributes.ContentState> {
        ActivityContent(
            state: FeedLiveActivityAttributes.ContentState(
                childID: snapshot.childID,
                childName: snapshot.childName,
                lastFeedKind: snapshot.lastFeedKind,
                lastFeedAt: snapshot.lastFeedAt,
                lastSleepAt: snapshot.lastSleepAt,
                activeSleepStartedAt: snapshot.activeSleepStartedAt,
                lastNappyAt: snapshot.lastNappyAt
            ),
            staleDate: nil,
            relevanceScore: 50
        )
    }

    private func log(_ level: LogLevel, _ message: String) {
        AppLogger.shared.log(level, category: "LiveActivity", message)
    }
}
